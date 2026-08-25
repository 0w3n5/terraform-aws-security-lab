# outputs main vpc id
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_a_id" {
  description = "ID of public subnet in AZ A"
  value       = aws_subnet.public_a.id
}

output "public_subnet_b_id" {
  description = "ID of public subnet in AZ B"
  value       = aws_subnet.public_b.id
}

output "private_subnet_a_id" {
  description = "ID of private subnet in AZ A"
  value       = aws_subnet.private_a.id
}

output "private_subnet_b_id" {
  description = "ID of private subnet in AZ B"
  value       = aws_subnet.private_b.id
}

# Internet Gateway Output 
output "internet_gateway_id" {
  value = aws_internet_gateway.gw.id
}

# Route table outputs
output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}

# Elastic IP for NAT gateway
output "elastic_ip" {
  value = aws_eip.nat.public_ip
}

# Flow log outputs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = aws_flow_log.main.id
}

output "vpc_flow_log_group_name" {
  description = "CloudWatch Log Group containing VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}