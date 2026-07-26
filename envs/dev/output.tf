output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "autoscaling_group_name" {
  value = module.compute.autoscaling_group_name
}
output "cloudwatch_dashboard_name" {
  value = module.observability.dashboard_name
}