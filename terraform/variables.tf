variable "region" {
  default = "eu-west-2"
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
}

variable "mail" {
  description = "E-mail to get websiet health notification"
  type        = string
}


