output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster (use via RDS Proxy in application code)"
  value       = module.aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = module.aurora.cluster_reader_endpoint
}

output "cluster_id" {
  description = "Identifier of the Aurora cluster"
  value       = module.aurora.cluster_id
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint - use this in application connection strings"
  value       = aws_db_proxy.this.endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials - pass to ECS task definitions"
  value       = aws_secretsmanager_secret.db.arn
}

output "aurora_security_group_id" {
  description = "Security group ID attached to the Aurora cluster and RDS Proxy"
  value       = aws_security_group.aurora.id
}
