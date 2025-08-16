variable "region" {
  default = "us-east-1"
}

variable "domain_name" {
  description = "Custom domain name used by R53 zone"
  type        = string
}

variable "mail" {
  description = "E-mail to get website health notification"
  type        = string
}


