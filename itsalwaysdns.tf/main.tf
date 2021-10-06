terraform {
  backend "s3" {
    key = "itsalwaysdns.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

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

# data

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ssilvidi-dev-tf-state-terraformstatebucket-1my31yzv88c0f"
    region = "us-east-2"
    key = "env:/dev/vpc.tfstate"
   }
}

data "terraform_remote_state" "imgmgr" {
  backend = "s3"
  config = {
    bucket = "ssilvidi-dev-tf-state-terraformstatebucket-1my31yzv88c0f"
    region = "us-east-2"
    key = "env:/dev/imgmgr.tfstate"
   }
}

data "aws_route53_zone" "example" {
  name         = "aws.silvidi.xyz"
  private_zone = false
}



# resources
resource "aws_route53_record" "name" {
  
}
resource "aws_acm_certificate" "example" {
  domain_name       = "imgmgr.aws.silvidi.xyz"
  validation_method = "DNS"
}


resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.example.zone_id
  name    = "imgmgr.${domain_name}"
  type    = "A"
  alias {
    name = data.terraform_remote_state.imgmgr.outputs
    # zone_id = 
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "example" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.example.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example : record.fqdn]
}

resource "aws_lb_listener" "example" {
  # ... other configuration ...

  certificate_arn = aws_acm_certificate_validation.example.certificate_arn
}

resource "aws_cloudfront_distribution" "cf" {
  enabled = true
  # aliases = ["imgmgr.${var.domain_name}"]
  aliases = ["imgmgr.aws.silvidi.xyz"]
}