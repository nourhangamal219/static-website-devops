# Provide Website URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.static-website-conf.website_endpoint
}

