output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic that receives CloudWatch alarm notifications"
  value       = aws_sns_topic.alarms.arn
}

output "alarm_sns_topic_name" {
  description = "Name of the alarms SNS topic"
  value       = aws_sns_topic.alarms.name
}

