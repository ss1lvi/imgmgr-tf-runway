output "lb_url" {
  value = join("",["http://",module.alb.lb_dns_name])
  description = "The Load Balancer URL for img-mgr"
}