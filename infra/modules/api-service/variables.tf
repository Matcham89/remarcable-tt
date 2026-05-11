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
  description = "Private subnets for ECS tasks"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets for the Application Load Balancer"
  type        = list(string)
}

variable "container_image" {
  description = "Full image URI for the API container"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "container_port" {
  description = "Port the API container listens on"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection on the API ALB"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Attach AWS managed WAF rules to the API ALB"
  type        = bool
  default     = false
}

variable "queue_url" {
  description = "SQS queue URL passed to the API so requests can enqueue heavy jobs"
  type        = string
}

variable "queue_arn" {
  description = "SQS queue ARN used by the API task role for SendMessage"
  type        = string
}

variable "db_host" {
  description = "Database hostname exposed to the app. Use the RDS Proxy endpoint, not the raw Aurora writer."
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256 | 512 | 1024 | 2048 | 4096)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Initial number of running API tasks (autoscaling adjusts from here)"
  type        = number
  default     = 2
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of API tasks"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of API tasks"
  type        = number
  default     = 10
}

variable "alb_certificate_arn" {
  description = "Optional ACM certificate ARN for the HTTPS listener on the ALB. Empty creates HTTP-only listener for demo."
  type        = string
  default     = ""
}

variable "db_secret_arn" {
  description = "Secrets Manager ARN for the DB credentials secret"
  type        = string
}

variable "app_secret_arn" {
  description = "Secrets Manager ARN for application secrets (API keys, etc.)"
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
}
