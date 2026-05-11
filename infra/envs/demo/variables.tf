variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "demo"
}

variable "project" {
  description = "Project name used as a prefix in resource names and tags"
  type        = string
}

variable "cost_centre" {
  description = "Cost centre tag applied to all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "AZs to deploy into"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one shared NAT Gateway for the demo. Set false for one NAT per AZ later."
  type        = bool
  default     = true
}

variable "enable_interface_vpc_endpoints" {
  description = "Create paid interface VPC endpoints for ECR, Secrets Manager, CloudWatch Logs, and SQS."
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "Aurora instance class. Keep small for demo; increase for production."
  type        = string
  default     = "db.t4g.medium"
}

variable "db_reader_count" {
  description = "Number of Aurora reader instances. Demo defaults to zero; set one or more for read scaling."
  type        = number
  default     = 0
}

variable "deletion_protection" {
  description = "Enable deletion protection for stateful resources before production."
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "Optional ACM certificate ARN for ALB HTTPS. Empty keeps the demo HTTP-only."
  type        = string
  default     = ""
}

variable "enable_waf" {
  description = "Attach AWS managed WAF rules to the API ALB. Keep false for the low-cost demo; enable before production."
  type        = bool
  default     = false
}

variable "container_image_api" {
  description = "Container image URI for the API service"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "container_image_worker" {
  description = "Container image URI for the worker service"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:1.27"
}

variable "api_task_cpu" {
  description = "CPU units for the API Fargate task"
  type        = number
  default     = 256
}

variable "api_task_memory" {
  description = "Memory in MiB for the API Fargate task"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Initial number of API tasks"
  type        = number
  default     = 1
}

variable "api_min_capacity" {
  description = "Minimum API task count"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Maximum API task count"
  type        = number
  default     = 4
}

variable "worker_task_cpu" {
  description = "CPU units for the worker Fargate task"
  type        = number
  default     = 256
}

variable "worker_task_memory" {
  description = "Memory in MiB for the worker Fargate task"
  type        = number
  default     = 512
}

variable "worker_min_capacity" {
  description = "Minimum worker task count"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_min_capacity >= 1
    error_message = "worker_min_capacity must be at least 1 so queue backlog scaling has a running service to measure."
  }
}

variable "worker_max_capacity" {
  description = "Maximum worker task count"
  type        = number
  default     = 6
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for CloudFront aliases. Must be in us-east-1 when set."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Optional custom domain aliases for CloudFront"
  type        = list(string)
  default     = []
}

variable "alarm_email" {
  description = "Optional email address for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
