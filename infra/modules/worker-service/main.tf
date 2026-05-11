data "aws_region" "current" {}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.4.0"

  repository_name         = "${var.project}-${var.environment}-worker"
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

module "task_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "${var.project}-${var.environment}-worker-task-sg"
  description = "Worker Fargate tasks have no inbound access"
  vpc_id      = var.vpc_id

  egress_rules = ["all-all"]
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project}/${var.environment}/worker"
  retention_in_days = 30
}

module "worker_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "7.5.0"

  name        = "${var.project}-${var.environment}-worker"
  cluster_arn = var.cluster_arn

  cpu    = var.task_cpu
  memory = var.task_memory

  enable_autoscaling    = false
  create_security_group = false
  desired_count         = var.autoscaling_min_capacity

  container_definitions = {
    worker = {
      image                  = var.container_image
      essential              = true
      readonlyRootFilesystem = false

      environment = [
        { name = "SQS_QUEUE_URL", value = var.queue_url },
        { name = "DATABASE_HOST", value = var.db_host },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = "app" }
      ]

      secrets = [
        { name = "DB_SECRET", valueFrom = var.db_secret_arn },
        { name = "APP_SECRET", valueFrom = var.app_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "worker"
        }
      }
    }
  }

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [module.task_sg.security_group_id]

  task_exec_secret_arns = [var.db_secret_arn, var.app_secret_arn]

  tasks_iam_role_statements = [
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ]
      resources = [var.queue_arn]
    }
  ]
}

# Scale on: ApproximateNumberOfMessagesVisible / RunningTaskCount
# The module keeps at least one worker running. That is deliberate for this
# brief: spikes should drain immediately, and the metric has a stable denominator.

resource "aws_appautoscaling_target" "worker" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${module.worker_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [module.worker_service]
}

resource "aws_appautoscaling_policy" "worker_backlog" {
  name               = "${var.project}-${var.environment}-worker-backlog"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker.resource_id
  scalable_dimension = aws_appautoscaling_target.worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.backlog_per_task_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    customized_metric_specification {
      metrics {
        id    = "m1"
        label = "SQS ApproximateNumberOfMessagesVisible"

        metric_stat {
          metric {
            namespace   = "AWS/SQS"
            metric_name = "ApproximateNumberOfMessagesVisible"
            dimensions {
              name  = "QueueName"
              value = var.queue_name
            }
          }
          stat = "Sum"
        }
        return_data = false
      }

      metrics {
        id    = "m2"
        label = "ECS RunningTaskCount"

        metric_stat {
          metric {
            namespace   = "ECS/ContainerInsights"
            metric_name = "RunningTaskCount"
            dimensions {
              name  = "ClusterName"
              value = var.cluster_name
            }
            dimensions {
              name  = "ServiceName"
              value = module.worker_service.name
            }
          }
          stat = "Average"
        }
        return_data = false
      }

      metrics {
        id          = "e1"
        label       = "BacklogPerTask"
        expression  = "m1 / FILL(m2, 1)"
        return_data = true
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "worker_task_count_zero" {
  alarm_name          = "${var.project}-${var.environment}-worker-no-tasks"
  alarm_description   = "No worker tasks are running"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = module.worker_service.name
  }
}
