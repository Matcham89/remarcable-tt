output "service_name" {
  description = "Name of the worker ECS service"
  value       = module.worker_service.name
}

output "service_id" {
  description = "Full ID of the worker ECS service"
  value       = module.worker_service.id
}

output "ecr_repository_url" {
  description = "ECR repository URL for the worker image"
  value       = module.ecr.repository_url
}

output "task_sg_id" {
  description = "Security group ID attached to worker tasks"
  value       = module.task_sg.security_group_id
}

output "task_execution_role_arn" {
  description = "ARN of the worker task execution role"
  value       = module.worker_service.task_exec_iam_role_arn
}
