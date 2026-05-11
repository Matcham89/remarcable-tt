output "cluster_arn" {
  description = "ARN of the ECS cluster - pass to worker-service module"
  value       = module.ecs_cluster.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster - used in CloudWatch metric dimensions and autoscaling"
  value       = module.ecs_cluster.name
}

output "service_name" {
  description = "Name of the API ECS service"
  value       = module.api_service.name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.api.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.api.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for CloudWatch metric dimensions"
  value       = aws_lb.api.arn_suffix
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB - used for Route53 alias records"
  value       = aws_lb.api.zone_id
}

output "ecr_repository_url" {
  description = "ECR repository URL for the API image"
  value       = module.ecr.repository_url
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role"
  value       = module.api_service.task_exec_iam_role_arn
}
