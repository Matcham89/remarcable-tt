data "aws_region" "current" {}

locals {
  enable_https = var.alb_certificate_arn != ""
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  repository_name         = "${var.project}-${var.environment}-api"
  repository_type         = "private"
  create_lifecycle_policy = true

  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images after 7 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 7
      }
      action = { type = "expire" }
    }]
  })

  repository_image_scan_on_push = true
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${var.project}-${var.environment}-api-alb-sg"
  description = "Internet-facing ALB allows HTTP and HTTPS from anywhere"
  vpc_id      = var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  egress_rules        = ["all-all"]
}

module "task_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${var.project}-${var.environment}-api-task-sg"
  description = "API Fargate tasks accept traffic from ALB only"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [{
    from_port                = var.container_port
    to_port                  = var.container_port
    protocol                 = "tcp"
    description              = "From ALB"
    source_security_group_id = module.alb_sg.security_group_id
  }]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]
}

resource "aws_lb" "api" {
  name               = "${var.project}-${var.environment}-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.alb_sg.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.alb_deletion_protection
}

resource "aws_lb_target_group" "api" {
  name        = "${var.project}-${var.environment}-api-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http_forward" {
  count = local.enable_https ? 0 : 1

  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_wafv2_web_acl" "alb" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project}-${var.environment}-api-alb-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-api-alb-crs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-api-alb-kbi"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-api-alb-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.api.arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "7.5.0"

  name = "${var.project}-${var.environment}-ecs"

  setting = [{
    name  = "containerInsights"
    value = "enabled"
  }]

  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = {
    fargate = {
      name   = "FARGATE"
      weight = 100
      base   = 1
    }
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project}/${var.environment}/api"
  retention_in_days = 30
}

module "api_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "7.5.0"

  name        = "${var.project}-${var.environment}-api"
  cluster_arn = module.ecs_cluster.arn

  cpu    = var.task_cpu
  memory = var.task_memory

  enable_autoscaling    = false
  create_security_group = false

  desired_count = var.desired_count

  container_definitions = {
    api = {
      image                  = var.container_image
      essential              = true
      readonlyRootFilesystem = false

      portMappings = [
        {
          name          = "api"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      secrets = [
        { name = "DB_SECRET", valueFrom = var.db_secret_arn },
        { name = "APP_SECRET", valueFrom = var.app_secret_arn }
      ]

      environment = [
        { name = "SQS_QUEUE_URL", value = var.queue_url },
        { name = "DATABASE_HOST", value = var.db_host },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "app" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  }

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.api.arn
      container_name   = "api"
      container_port   = var.container_port
    }
  }

  subnet_ids = var.private_subnet_ids

  security_group_ids = [module.task_sg.security_group_id]

  task_exec_secret_arns = [var.db_secret_arn, var.app_secret_arn]

  tasks_iam_role_statements = [
    {
      effect    = "Allow"
      actions   = ["sqs:SendMessage"]
      resources = [var.queue_arn]
    }
  ]
}

resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${module.ecs_cluster.name}/${module.api_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [module.api_service]
}

resource "aws_appautoscaling_policy" "api_requests" {
  name               = "${var.project}-${var.environment}-api-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 1000
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.api.arn_suffix}/${aws_lb_target_group.api.arn_suffix}"
    }
  }
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.project}-${var.environment}-api-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.project}-${var.environment}-api-5xx-high"
  alarm_description   = "ALB 5xx error rate elevated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.api.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project}-${var.environment}-api-latency-high"
  alarm_description   = "ALB target response time above 2 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.api.arn_suffix
  }
}
