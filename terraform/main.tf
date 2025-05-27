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

