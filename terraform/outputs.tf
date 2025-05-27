# Provide Website URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.static-website-conf.website_endpoint
}

output "cdn_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
