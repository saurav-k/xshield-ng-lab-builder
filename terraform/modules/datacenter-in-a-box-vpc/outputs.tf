output "vpc_id" {
    description = "The VPC id"
    value = aws_vpc.vpc.id
}

output "public_subnet_id" {
    description = "The public subnet id"
    value = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
    description = "The first private subnet id"
    value = aws_subnet.private_subnet.id
}

output "private_subnet_id_2" {
    description = "The first private subnet id"
    value = aws_subnet.private_subnet_2.id
}

output "private_subnet_ids" {
    description = "The first private subnet name"
    value = tolist([ aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id ])
}

output "nat_is_ready" {
    description = "The NAT GW is ready!"
    value = "${null_resource.nat_ready.id}"
}

output "private_subnet_rt_id" {
    description = "Private subnet route table id"
    value = aws_route_table.rt_private.id
}