variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region used in CloudWatch dashboard widgets"
  type        = string
}

variable "alarm_email" {
  description = "Email address to subscribe to the alarms SNS topic. Leave empty to skip email subscription."
  type        = string
  default     = ""
}

