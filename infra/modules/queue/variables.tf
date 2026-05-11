variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic to send CloudWatch alarm notifications to"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "SQS message visibility timeout. Must be >= your worker task's max processing time."
  type        = number
  default     = 30
}

variable "max_receive_count" {
  description = "Number of times a message is received before being moved to the DLQ"
  type        = number
  default     = 5
}

variable "dlq_depth_alarm_threshold" {
  description = "DLQ message count that triggers an alarm. Any message in the DLQ = a processing failure."
  type        = number
  default     = 0
}
