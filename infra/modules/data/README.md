# Module: data

Aurora PostgreSQL provisioned cluster (writer + reader), RDS Proxy for connection pooling, and Secrets Manager secret for DB credentials.

## Usage

```hcl
module "data" {
  source = "../../modules/data"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
