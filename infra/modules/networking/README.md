# Module: networking

VPC, public/private subnets, NAT Gateways with pre-allocated Elastic IPs, and interface VPC endpoints (ECR, Secrets Manager, CloudWatch Logs, SQS) plus S3 gateway endpoint.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
