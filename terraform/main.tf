# Provider Information
provider "aws" {
  region = var.region
}

# Create S3 bucket where the files will be stored
resource "aws_s3_bucket" "static-website-bucket" {
  bucket = var.bucket_name
  region = var.region
  tags = {
    Name  = "my-devops-website.com"
  }
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

# Edit Block Public Access settings
resource "aws_s3_bucket_public_access_block" "allow-access" {
  bucket = aws_s3_bucket.static-website-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Add a bucket policy that makes your bucket content publicly available
resource "aws_s3_bucket_policy" "public-content" {
  bucket = aws_s3_bucket.static-website-bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.static-website-bucket.arn}/*"
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
    domain_name              = var.domain_name
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
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CDN-Static-Website"
  }
}



  
