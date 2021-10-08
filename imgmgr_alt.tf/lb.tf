module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "my-alb"

  load_balancer_type = "application"

  vpc_id             = data.terraform_remote_state.vpc_alt.outputs.vpc_id
  subnets            = data.terraform_remote_state.vpc_alt.outputs.public_subnets
  security_groups    = [module.sg_lb.security_group_id]

  target_groups = [
    {
      name_prefix      = var.application
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]
}