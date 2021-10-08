provider "aws" {
  profile = "default"
  region  = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Application = var.application
    }
  }
}

data "terraform_remote_state" "vpc_alt" {
  backend = "s3"
  config = {
    bucket = "ssilvidi-dev-tf-state-terraformstatebucket-1my31yzv88c0f"
    region = "us-east-2"
    key = "env:/dev/vpc_alt.tfstate"
   }
}

data "aws_ami" "latest_amazon2" {
# finds the latest amazon linux 2 AMI
  owners = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_s3_bucket" "img_bucket" {
  bucket_prefix = "${var.customer}-${var.environment}-"
}

