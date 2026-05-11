output "nat_public_ips" {
  description = "Public IPs of the NAT Gateways; share these with partners for firewall whitelisting"
  value       = aws_eip.nat[*].public_ip
}

output "alb_dns_name" {
  description = "DNS name of the API Application Load Balancer"
  value       = module.api_service.alb_dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name for the frontend"
  value       = module.frontend.distribution_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.frontend.distribution_id
}

output "ecr_api_url" {
  description = "ECR repository URL for the API image"
  value       = module.api_service.ecr_repository_url
}

output "ecr_worker_url" {
  description = "ECR repository URL for the worker image"
  value       = module.worker_service.ecr_repository_url
}

output "db_proxy_endpoint" {
  description = "RDS Proxy endpoint for application DATABASE_URL"
  value       = module.data.proxy_endpoint
}

output "app_secret_arn" {
  description = "Secrets Manager ARN for application secrets"
  value       = aws_secretsmanager_secret.app.arn
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = module.queue.queue_url
}
