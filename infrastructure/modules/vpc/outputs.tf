output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID of the VPC"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public : s.id]
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "IDs of private subnets"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.this.id
  description = "ID of Internet Gateway"
}

output "nat_gateway_ids" {
  value       = [for n in aws_nat_gateway.this : n.id]
  description = "IDs of NAT Gateways"
}

