resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-nat-${element(var.availability_zones, count.index)}"
  }
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}/${var.environment}/app"
  description             = "Application secrets for ${var.project} ${var.environment}"
  recovery_window_in_days = 0
}

resource "random_password" "django_secret_key" {
  length  = 64
  special = true
}

resource "random_password" "db_master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DJANGO_SECRET_KEY = random_password.django_secret_key.result
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

moved {
  from = aws_secretsmanager_secret_version.app_placeholder
  to   = aws_secretsmanager_secret_version.django_secret_key
}

module "observability" {
  source = "../../modules/observability"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region
  alarm_email = var.alarm_email
}

module "networking" {
  source = "../../modules/networking"

  project                        = var.project
  environment                    = var.environment
  vpc_cidr                       = var.vpc_cidr
  availability_zones             = var.availability_zones
  private_subnet_cidrs           = var.private_subnet_cidrs
  public_subnet_cidrs            = var.public_subnet_cidrs
  single_nat_gateway             = var.single_nat_gateway
  external_nat_ip_ids            = aws_eip.nat[*].allocation_id
  enable_interface_vpc_endpoints = var.enable_interface_vpc_endpoints
}

module "queue" {
  source = "../../modules/queue"

  project             = var.project
  environment         = var.environment
  alarm_sns_topic_arn = module.observability.alarm_sns_topic_arn
}

module "data" {
  source = "../../modules/data"

  project             = var.project
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  vpc_cidr_block      = module.networking.vpc_cidr_block
  private_subnet_ids  = module.networking.private_subnet_ids
  instance_class      = var.db_instance_class
  reader_count        = var.db_reader_count
  db_password         = random_password.db_master_password.result
  deletion_protection = var.deletion_protection
  alarm_sns_topic_arn = module.observability.alarm_sns_topic_arn
}

module "api_service" {
  source = "../../modules/api-service"

  project             = var.project
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  container_image     = var.container_image_api
  alb_certificate_arn = var.alb_certificate_arn
  enable_waf          = var.enable_waf
  queue_url           = module.queue.queue_url
  queue_arn           = module.queue.queue_arn
  db_host             = module.data.proxy_endpoint
  db_secret_arn       = module.data.db_secret_arn
  app_secret_arn      = aws_secretsmanager_secret.app.arn
  alarm_sns_topic_arn = module.observability.alarm_sns_topic_arn

  task_cpu    = var.api_task_cpu
  task_memory = var.api_task_memory

  desired_count            = var.api_desired_count
  autoscaling_min_capacity = var.api_min_capacity
  autoscaling_max_capacity = var.api_max_capacity

  depends_on = [aws_secretsmanager_secret_version.django_secret_key]
}

module "worker_service" {
  source = "../../modules/worker-service"

  project             = var.project
  environment         = var.environment
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  cluster_arn         = module.api_service.cluster_arn
  cluster_name        = module.api_service.cluster_name
  queue_url           = module.queue.queue_url
  queue_arn           = module.queue.queue_arn
  queue_name          = module.queue.queue_name
  container_image     = var.container_image_worker
  db_host             = module.data.proxy_endpoint
  db_secret_arn       = module.data.db_secret_arn
  app_secret_arn      = aws_secretsmanager_secret.app.arn
  alarm_sns_topic_arn = module.observability.alarm_sns_topic_arn

  task_cpu    = var.worker_task_cpu
  task_memory = var.worker_task_memory

  autoscaling_min_capacity = var.worker_min_capacity
  autoscaling_max_capacity = var.worker_max_capacity

  depends_on = [aws_secretsmanager_secret_version.django_secret_key]
}

module "frontend" {
  source = "../../modules/frontend"

  project             = var.project
  environment         = var.environment
  acm_certificate_arn = var.acm_certificate_arn
  domain_aliases      = var.domain_aliases
}
