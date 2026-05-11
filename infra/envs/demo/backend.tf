terraform {
  backend "s3" {
    bucket       = "remarcable-state-342677169881-us-east-1-an"
    key          = "demo/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
