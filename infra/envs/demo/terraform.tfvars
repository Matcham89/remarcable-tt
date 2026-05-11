aws_region  = "us-east-1"
environment = "demo"
project     = "remarcable"
cost_centre = "engineering"

vpc_cidr             = "10.10.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
public_subnet_cidrs  = ["10.10.101.0/24", "10.10.102.0/24"]

# Demo cost posture: one NAT, no paid interface endpoints, one small writer.
# Set single_nat_gateway=false, enable_interface_vpc_endpoints=true, and
# db_reader_count=1 when promoting this shape toward production.
single_nat_gateway             = true
enable_interface_vpc_endpoints = false
db_instance_class              = "db.t4g.medium"
db_reader_count                = 0
deletion_protection            = false

api_task_cpu      = 256
api_task_memory   = 512
api_desired_count = 1
api_min_capacity  = 1
api_max_capacity  = 4

worker_task_cpu     = 256
worker_task_memory  = 512
worker_min_capacity = 1
worker_max_capacity = 6

alarm_email = ""

# Optional custom domains/certificates. Empty values keep the demo deployable
# without Route53 or ACM setup.
# enable_waf          = true
# alb_certificate_arn = "arn:aws:acm:us-east-1:342677169881:certificate/XXXX"
# acm_certificate_arn = "arn:aws:acm:us-east-1:342677169881:certificate/XXXX"
# domain_aliases      = ["demo.remarcable.com"]
