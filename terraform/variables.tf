variable "region" {
  default = "eu-west-2"
}

variable "bucket_name" {
  description = "S3 bucket for static site"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
}
