output "bucket_id" {
  description = "S3 bucket name for the frontend assets"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3_bucket.s3_bucket_arn
}

output "distribution_id" {
  description = "CloudFront distribution ID - used in CI/CD to invalidate the cache after a deploy"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (e.g. d1234.cloudfront.net)"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_arn
}
