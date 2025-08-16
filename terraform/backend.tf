terraform {
  backend "s3" {
    bucket         = "noura-tf-state-bucket"
    key            = "devops-static-site/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
