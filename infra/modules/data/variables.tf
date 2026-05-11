variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy Aurora and RDS Proxy into"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block - used to scope Aurora security group ingress"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the Aurora DB subnet group and RDS Proxy"
  type        = list(string)
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.6"
}

variable "instance_class" {
  description = "Aurora instance class for writer and reader"
  type        = string
  default     = "db.t4g.medium"
}

variable "reader_count" {
  description = "Number of Aurora reader instances to create in addition to the writer"
  type        = number
  default     = 0

  validation {
    condition     = var.reader_count >= 0 && var.reader_count <= 5
    error_message = "reader_count must be between 0 and 5."
  }
}

variable "db_password" {
  description = "Master password for the Aurora cluster. Stored in Secrets Manager; never logged."
  type        = string
  sensitive   = true
}

variable "deletion_protection" {
  description = "Enable deletion protection on the Aurora cluster"
  type        = bool
  default     = false
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
}
