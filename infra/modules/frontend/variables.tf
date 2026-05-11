variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the CloudFront distribution. Must be in us-east-1."
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Custom domain aliases for the CloudFront distribution (e.g. [\"app.example.com\"]). Leave empty to use the CloudFront default *.cloudfront.net domain."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.domain_aliases) == 0 || var.acm_certificate_arn != ""
    error_message = "acm_certificate_arn is required when domain_aliases is not empty."
  }
}

variable "price_class" {
  description = "CloudFront price class - controls which edge locations are used"
  type        = string
  default     = "PriceClass_100"
}
