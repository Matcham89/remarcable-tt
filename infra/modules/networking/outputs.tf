output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (used by ECS tasks, Aurora, RDS Proxy)"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (used by the ALB)"
  value       = module.vpc.public_subnets
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "nat_public_ips" {
  description = "Public IP addresses of the NAT Gateways - give these to partners for whitelisting"
  value       = module.vpc.nat_public_ips
}

output "vpc_endpoint_sg_id" {
  description = "Security group ID attached to interface VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}
