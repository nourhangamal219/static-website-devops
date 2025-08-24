variable "region" {
  default = "us-east-1"
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
}

variable "mail" {
  description = "E-mail to get site health notification"
  type        = string
}


