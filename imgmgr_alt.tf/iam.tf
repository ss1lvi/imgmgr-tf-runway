# resource "aws_iam_instance_profile" "instance_profile" {
#   role = module.iam_role_imgmgr.iam_instance_profile_arn
# }

module "iam_role_imgmgr" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.3"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role = true
  create_instance_profile = true

  role_name         = "imgmgr_role2"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    module.iam_policy_imgmgr.arn
  ]
   number_of_custom_role_policy_arns = 2
}

module "iam_policy_imgmgr" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.3"

  name        = "imgmgr_policy2"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.img_bucket.arn}/*"
    },
    {
      "Action": ["s3:ListBucket"],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.img_bucket.arn}"
    },
    {
      "Action": ["ec2:DescribeTags"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}