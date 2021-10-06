terraform {
  backend "s3" {
    key = "imgmgr.tfstate"
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

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "ssilvidi-dev-tf-state-terraformstatebucket-1my31yzv88c0f"
    region = "us-east-2"
    key = "env:/dev/vpc.tfstate"
   }
}

data "aws_ami" "latest-amazon2" {
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

resource "aws_iam_instance_profile" "instance_profile" {
  role = aws_iam_role.imgmgr_role.name
}

resource "aws_iam_role" "imgmgr_role" {
  name = "imgmgr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]

  inline_policy {
    name = "s3getputdelete"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Effect = "Allow"
          Resource = "${aws_s3_bucket.img_bucket.arn}/*"
        }
      ]
    })
  }

  inline_policy {
    name = "s3listbucket"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["s3:ListBucket"]
          Effect = "Allow"
          Resource = aws_s3_bucket.img_bucket.arn
        }
      ]
    })
  }

  inline_policy {
    name = "ec2desctags"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["ec2:DescribeTags"]
          Effect = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_s3_bucket" "img_bucket" {
  bucket_prefix = "${var.customer}-${var.environment}-"
}

resource "aws_lb" "load_balancer" {
  security_groups = [aws_security_group.sg_lb.id]
  subnets = data.terraform_remote_state.vpc.outputs.public_subnets
}

resource "aws_alb_target_group" "lb_targets" {
  port = 80
  protocol = "HTTP"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_alb_listener" "lb_http" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.lb_targets.arn
  }
}

resource "aws_security_group" "sg_lb" {
  description = "allow http from internet"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "sg_server" {
  description = "allow http to app servers"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      security_groups  = [aws_security_group.sg_lb.id]
  }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_template" "imgmgr_template" {
  name = "imgmgr_template"
  image_id = data.aws_ami.latest-amazon2.image_id
  instance_type = var.instance_type
  key_name = var.ssh_key
  vpc_security_group_ids = [aws_security_group.sg_server.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }

  user_data = base64encode(templatefile("${path.module}/install.sh", { S3Bucket = aws_s3_bucket.img_bucket.id }))
}

resource "aws_autoscaling_group" "app_server_group" {
  name_prefix = "${var.customer}-${var.environment}-"
  max_size = var.app_server_max_count
  min_size = var.app_server_min_count
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnets
  health_check_grace_period = 300
  health_check_type = var.health_check_type
  target_group_arns = [aws_alb_target_group.lb_targets.arn]

  launch_template {
    id = aws_launch_template.imgmgr_template.id
    version = "$Latest"
  }
}


# outputs
output "imgmgr_url" {
  value = join("",["http://",aws_lb.load_balancer.dns_name])
  description = "The URL for "
}