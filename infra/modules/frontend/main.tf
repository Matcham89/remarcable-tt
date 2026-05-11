locals {
  use_custom_domain = length(var.domain_aliases) > 0
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = "${var.project}-${var.environment}-frontend"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = var.environment != "prod"

  versioning = {
    enabled = false
  }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project}-${var.environment}-frontend-s3-oac"
  description                       = "OAC for ${var.project} ${var.environment} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.4.1"

  comment             = "${var.project} ${var.environment} frontend"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  default_root_object = "index.html"

  aliases = local.use_custom_domain ? var.domain_aliases : []

  viewer_certificate = {
    acm_certificate_arn            = local.use_custom_domain ? var.acm_certificate_arn : null
    cloudfront_default_certificate = local.use_custom_domain ? null : true
    ssl_support_method             = local.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.use_custom_domain ? "TLSv1.2_2021" : null
  }

  create_origin_access_control = false

  origin = {
    s3 = {
      domain_name              = module.s3_bucket.s3_bucket_bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id      = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    use_forwarded_values = false

    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
  }

  # SPA routing: CloudFront returns 403/404 for missing keys -> serve index.html
  # so the React router handles the path client-side.
  custom_error_response = [
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 0
    },
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 0
    }
  ]
}

# The aws:SourceArn condition locks access to this specific distribution -
# even if someone obtains the bucket name, they cannot bypass CloudFront.
resource "aws_s3_bucket_policy" "frontend" {
  bucket = module.s3_bucket.s3_bucket_id
  policy = data.aws_iam_policy_document.frontend_s3.json

  depends_on = [module.cloudfront]
}

data "aws_iam_policy_document" "frontend_s3" {
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${module.s3_bucket.s3_bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cloudfront.cloudfront_distribution_arn]
    }
  }
}
