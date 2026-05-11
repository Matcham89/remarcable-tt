variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for worker ECS tasks"
  type        = list(string)
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster (from api-service module output)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (from api-service module output)"
  type        = string
}

variable "queue_url" {
  description = "SQS queue URL passed to the worker container as SQS_QUEUE_URL"
  type        = string
}

variable "queue_arn" {
  description = "SQS queue ARN - used in IAM task role policy"
  type        = string
}

variable "queue_name" {
  description = "SQS queue name - used in CloudWatch metric dimensions"
  type        = string
}

variable "container_image" {
  description = "Full ECR image URI for the worker container"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "db_host" {
  description = "Database hostname exposed to the worker. Use the RDS Proxy endpoint, not the raw Aurora writer."
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the worker Fargate task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the worker Fargate task"
  type        = number
  default     = 512
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of worker tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.autoscaling_min_capacity >= 1
    error_message = "autoscaling_min_capacity must be at least 1 so queue backlog scaling has a running service to measure."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of worker tasks"
  type        = number
  default     = 20
}

variable "backlog_per_task_target" {
  description = "Target number of SQS messages per running worker task before scaling out"
  type        = number
  default     = 10
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  type        = string
}

variable "app_secret_arn" {
  description = "Secrets Manager ARN for application secrets"
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
}
