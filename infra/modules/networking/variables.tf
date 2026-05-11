variable "project" {
  description = "Project name - used as a prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of AZs to deploy into"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets - one per AZ"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets - one per AZ"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT Gateway"
  type        = bool
  default     = false
}

variable "external_nat_ip_ids" {
  description = "Allocation IDs of pre-created aws_eip resources to use as NAT Gateway IPs. Pass these from the env composition so the public IPs survive NAT GW replacement."
  type        = list(string)
}

variable "enable_interface_vpc_endpoints" {
  description = "Create paid interface VPC endpoints for AWS APIs. Keep false for the demo to reduce fixed monthly cost."
  type        = bool
  default     = false
}
