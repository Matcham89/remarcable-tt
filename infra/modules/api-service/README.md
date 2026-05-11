# Module: api-service

ECR repository, ECS cluster, ALB, WAFv2 (managed rule sets), ECS Fargate service (Express Mode pattern), and dual-policy autoscaling (RequestCountPerTarget + CPU).

## Usage

```hcl
module "api_service" {
  source = "../../modules/api-service"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
