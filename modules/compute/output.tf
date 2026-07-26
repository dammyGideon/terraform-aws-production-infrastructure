output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "target_group_arn" {
  description = "ARN of the application Target Group"
  value       = aws_lb_target_group.app.arn
}

output "load_balancer_arn_suffix" {
  description = "ALB ARN suffix used by cloudwatch dimensions"
  value = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ALB Target Group ARN suffix used by cloudwatch dimensions"
  value = aws_lb_target_group.app.arn_suffix
}

