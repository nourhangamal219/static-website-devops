# Provide Website URL
output "website_url" {
  value = aws_s3_bucket.static_site.website_endpoint
}
