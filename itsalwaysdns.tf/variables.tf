variable "aws_region" {
  type        = string
  description = "the AWS region to use"
  default     = "us-east-1"
}

variable "application" {
  type = string
  description = "name of the application"
}

variable "environment" {
  type        = string
  description = "the environment (prod, dev, etc.)"
}

variable "hosted_zone" {
  type = string
  description = "your hosted zone in route 53"
}