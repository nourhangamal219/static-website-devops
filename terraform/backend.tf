terraform {
  backend "s3" {
    bucket         = "noura-tf-state-bucket"
    key            = "devops-static-site/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
