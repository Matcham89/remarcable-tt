resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.environment}-jobs-dlq"
  message_retention_seconds = 1209600 # 14 days - maximum retention for DLQ forensics
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.project}-${var.environment}-jobs"
  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.project}-${var.environment}-jobs-dlq-not-empty"
  alarm_description   = "Messages landed in the DLQ - worker failed to process after ${var.max_receive_count} attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = var.dlq_depth_alarm_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_sns_topic_arn]
  ok_actions          = [var.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "queue_depth_high" {
  alarm_name          = "${var.project}-${var.environment}-jobs-queue-depth-high"
  alarm_description   = "Main queue depth is unexpectedly high - worker may be falling behind"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 500
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_sns_topic_arn]

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }
}
