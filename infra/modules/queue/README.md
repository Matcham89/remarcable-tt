# Module: queue

SQS standard queue + dead-letter queue with CloudWatch alarms for DLQ depth and queue backlog.

## Usage

```hcl
module "queue" {
  source = "../../modules/queue"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
