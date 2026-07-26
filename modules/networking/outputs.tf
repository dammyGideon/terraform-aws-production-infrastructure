output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnets_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnets_ids" {
  value = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  value = aws_security_group.alb-sg.id
}


output "app_security_group_id" {
  value = aws_security_group.app-sg.id
}

output "database_security_group_id" {
  value = aws_security_group.database-sg.id
}
