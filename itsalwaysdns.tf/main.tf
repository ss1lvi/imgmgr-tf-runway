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

data "terraform_remote_state" "imgmgr" {
  backend = "s3"
  config = {
    bucket = "ssilvidi-dev-tf-state-terraformstatebucket-1my31yzv88c0f"
    region = "us-east-2"
    key = "env:/dev/imgmgr.tfstate"
   }
}

data "aws_route53_zone" "myzone" {
  name         = var.hosted_zone
  private_zone = false
}

# resources

resource "aws_acm_certificate" "cert" {
  domain_name       = "imgmgr.${var.hosted_zone}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = "imgmgr.${var.hosted_zone}"
  type    = "A"
  alias {
    name = trimprefix(data.terraform_remote_state.imgmgr.outputs.cloudfront_url, "https://")
    zone_id = data.terraform_remote_state.imgmgr.outputs.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.myzone.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# outputs

output "domain_name" {
  value = aws_route53_record.www.name
}

output "cert" {
  value = aws_acm_certificate.cert.arn
}