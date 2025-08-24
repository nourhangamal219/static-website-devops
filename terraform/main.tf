# Provider Information
provider "aws" {
  region = var.region
}

# Another provider for ACM certificate
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Create R53 Zone
resource "aws_route53_zone" "domain" {
  name = var.domain_name
}

# Create ACM certificate
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Add cert validation records in R53 zone
resource "aws_route53_record" "add-cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.domain.zone_id
}

# Validate Cert
resource "aws_acm_certificate_validation" "cert-validate" {
  provider          = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.add-cert : record.fqdn]
}

# Create S3 bucket where the files will be stored
resource "aws_s3_bucket" "static-website-bucket" {
  bucket = var.domain_name
  region = var.region
}

#Enable Static Website Hosting on S3 bucker
resource "aws_s3_bucket_website_configuration" "static-website-conf" {
  bucket = aws_s3_bucket.static-website-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# Add a bucket policy that makes your bucket content publicly available
resource "aws_s3_bucket_policy" "public-content" {
  bucket = aws_s3_bucket.static-website-bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.static-website-bucket.arn}/*"
      Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site-cache.arn
          }
    }]
  })
}

# set S3 as origin for CloudFront
resource "aws_cloudfront_origin_access_control" "s3-origin" {
  name                              = "static-website-origin"
  description                       = "Origin for static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create CloudFront for caching
resource "aws_cloudfront_distribution" "site-cache" {
  origin {
    domain_name              = aws_s3_bucket.static-website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3-origin.id
    origin_id                = "S3Origin"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
aliases = [var.domain_name]
tags = {
    Name = "CDN-Static-Website"
  }
depends_on = [aws_acm_certificate_validation.cert-validate]
}

resource "aws_route53_record" "cdn_alias" {
  zone_id = aws_route53_zone.domain.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site-cache.domain_name
    zone_id                = aws_cloudfront_distribution.site-cache.hosted_zone_id
    evaluate_target_health = true
  }
}

# Create Health Check 
resource "aws_route53_health_check" "site_health" {
  fqdn              = var.domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/index.html"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "StaticSiteHealthCheck"
  }
}

# Create Health Check for s3 endpoint
resource "aws_route53_health_check" "s3-health" {
  fqdn              = aws_s3_bucket.static-website-bucket.bucket_regional_domain_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/index.html"
  failure_threshold = 3
  request_interval  = 30
}

# Create SNS Topic
resource "aws_sns_topic" "health-check" {
  name = "my-site-health-check"
}

# Create SNS Subscription
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.health-check.arn
  protocol  = "email"
  endpoint  = var.mail
}

# Create Cloudwatch Alert
resource "aws_cloudwatch_metric_alarm" "s3_health_alarm" {
  alarm_name          = "S3HealthFail"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    HealthCheckId = aws_route53_health_check.s3-health.id
  }

  alarm_actions = [aws_sns_topic.health-check.arn]
}

resource "aws_cloudwatch_metric_alarm" "site_health_alarm" {
  alarm_name          = "SiteHealthFail"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    HealthCheckId = aws_route53_health_check.site_health.id
  }

  alarm_actions = [aws_sns_topic.health-check.arn]
}


  
