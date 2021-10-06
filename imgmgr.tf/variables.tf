variable "aws_region" {
  type        = string
  description = "the AWS region to use"
  default     = "us-east-2"
}

variable "customer" {
  type        = string
  description = "name of customer"
}

variable "application" {
  type = string
  description = "name of the application"
}

variable "environment" {
  type        = string
  description = "the environment (prod, dev, etc.)"
}

variable "ssh_key" {
  type = string
  description = "ssh key pair"
}

variable "image_id" {
  type = string
  description = "AMI to base the instance off of"
}

variable "vpc_id" {
  type = string
  description = "vpc the resources are launched within"
}

variable "load_balancer_subnets" {
  type = list(string)
  description = "list of subnets for ELB"
}

variable "app_subnets" {
  type = list(string)
  description = "subnets for instances to live within"
}

variable "app_server_min_count" {
  type = number
  description = "minimum number of instances to run"
}

variable "app_server_max_count" {
  type = number
  description = "maximum number of instances to run"
}

variable "availability_zones" {
  type = list(string)
  description = "which AZs to launch instances into"
}

variable "health_check_type" {
  type = string
  description = "which ELB health check type to use"
  default = "EC2"
}

variable "instance_type" {
  type = string
  description = "instance size for the app servers"
}

variable "scale_out_threshold" {
  type = number
  description = "CPU utilization threshold to scale out instances"
}

variable "scale_in_threshold" {
  type = number
  description = "CPU utilization threshold to scale in instances"
}