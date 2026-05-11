# Module: worker-service

ECR repository, ECS Fargate service (no ALB), and BacklogPerTask autoscaling (SQS ApproximateNumberOfMessagesVisible / RunningTaskCount).

## Usage

```hcl
module "worker_service" {
  source = "../../modules/worker-service"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
