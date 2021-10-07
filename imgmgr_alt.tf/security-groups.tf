module "sg_lb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name = "sg_lb"
  description = "allow http from internet"
  vpc_id = data.terraform_remote_state.vpc_alt.outputs.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["http-80-tcp"]

  egress_rules = ["all-all"]
}

module "sg_server" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name = "sg_server"
  description = "allow http to app servers"
  vpc_id = data.terraform_remote_state.vpc_alt.outputs.vpc_id

  ingress_with_source_security_group_id = [
    {
      rule = "http-80-tcp"
      source_security_group_id = module.sg_lb.security_group_id
    }
  ]

  egress_rules = ["all-all"]
}