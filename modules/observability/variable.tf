variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "load_balancer_arn_suffix" {
  type = string
}


variable "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group"
  type        = string
}

variable "alert_email" {
  description = "Email address that receives infrastructure alerts"
  type        = string
}
