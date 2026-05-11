# Module: observability

SNS alarm topic (with optional email subscription), CloudWatch dashboard, and pre-created Aurora log group with retention policy.

## Usage

```hcl
module "observability" {
  source = "../../modules/observability"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
