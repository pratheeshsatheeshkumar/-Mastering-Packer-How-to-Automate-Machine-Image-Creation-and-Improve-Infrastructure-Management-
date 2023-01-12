variable "access_key" {
  default     = "XXXXXXX"
  description = "access key of the provider"
}

variable "secret_key" {
  default     = "YYYYYYYY"
  description = "secret key of the provider"
}


variable "project" {
  type    = string
  default = "zomato"
}
variable "environment" {
  type    = string
  default = "prod"
}

variable "regions" {
  type = map(string)
  default = {
    "region1" = "ap-south-1"
    "region2" = "us-east-1"
  }
}

variable "source_ami" {

  type = map(string)
  default = {
    "ap-south-1" = "ami-0cca134ec43cf708f"
    "us-east-1"  = "ami-0b5eea76982371e91"
  }
}
locals {
  image-timestamp = "${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  image-name      = "${var.project}-${var.environment}-${local.image-timestamp}"
}
