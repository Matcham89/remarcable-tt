# Module: frontend

S3 bucket (private) and CloudFront distribution with OAC (SigV4) for a React SPA. SPA routing handled via custom error responses.

## Usage

```hcl
module "frontend" {
  source = "../../modules/frontend"

  project     = "remarcable"
  environment = "demo"
}
```

## Inputs

See `variables.tf`.

## Outputs

See `outputs.tf`.
