module "asg_imgmgr" {
  source = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  # Autoscaling group
  name            = var.application
  use_name_prefix = true

  vpc_zone_identifier = data.terraform_remote_state.vpc_alt.outputs.public_subnets
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  health_check_type   = var.health_check_type
  target_group_arns   = module.alb.target_group_arns
  lt_version          = "$Latest"

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 0
    }
    triggers = ["tag"]
  }

  # Launch template
  use_lt    = true
  create_lt = true

  lt_name                  = var.application
  lt_use_name_prefix       = true
  update_default_version   = true
  image_id                 = data.aws_ami.latest_amazon2.image_id
  instance_type            = "t2.micro"
  key_name                 = var.ssh_key
  iam_instance_profile_arn = module.iam_role_imgmgr.iam_instance_profile_arn
  security_groups          = [module.sg_server.security_group_id]
  user_data_base64         = base64encode(templatefile("${path.module}/install.sh", { S3Bucket = aws_s3_bucket.img_bucket.id }))
}
