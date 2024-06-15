output "vpc_id" {
    description = "The VPC id"
    value = aws_vpc.vpc.id
}

output "public_subnet_1_id" {
    description = "The public subnet id"
    value = aws_subnet.public_subnet_1.id
}

output "private_subnet_1_id" {
    description = "The first private subnet id"
    value = aws_subnet.private_subnet_1.id
}

output "nat_is_ready" {
    description = "The NAT GW is ready!"
    value = "${null_resource.nat_ready.id}"
}