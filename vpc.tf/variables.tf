variable "aws_region" {
  type        = string
  description = "the AWS region to use"
  default     = "us-east-2"
}

variable "customer" {
  type        = string
  description = "name of customer"
  default     = "ssilvidi"
}

variable "environment" {
  type        = string
  description = "the environment (prod, dev, etc.)"
  default     = "test"
}

variable "vpc_cidr" {
  type        = string
  description = "the CIDR block for your VPC"
  default     = "10.220.0.0/16"
}

