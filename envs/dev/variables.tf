variable "aws_region" {
  type        = string
  description = "Aws region where the dev infrastructure will be deployed"
}


variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRa for public subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability Zones to use"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
}