customer = "ssilvidi"
application = "imgmgr"
environment = "dev"
ssh_key = "ohioKey"
image_id = ""
vpc_id = ""
load_balancer_subnets = [""]
app_subnets = [""]
app_server_min_count = 2
app_server_max_count = 4
availability_zones = [""]
health_check_type = "EC2"
instance_type = "t2.micro"
scale_out_threshold = 50
scale_in_threshold = 15
cf_alias = "imgmgr.aws.silvidi.com"