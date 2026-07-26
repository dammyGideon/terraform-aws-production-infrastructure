output "dashboard_name" {
  description = "Name of the CloudWatch operations dashboard"
  value       = aws_cloudwatch_dashboard.operations.dashboard_name
}