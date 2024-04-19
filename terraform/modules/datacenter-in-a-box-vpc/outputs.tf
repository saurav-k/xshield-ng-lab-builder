output "vpc_id" {
    description = "The VPC id"
    value = aws_vpc.vpc.id
}

output "dmz_public_subnet_id" {
    description = "The DMZ public subnet id"
    value = aws_subnet.dmz_public_subnet.id
}

output "prd_public_subnet_id" {
    description = "The PRD public subnet id"
    value = aws_subnet.prd_public_subnet.id
}

output "tst_public_subnet_id" {
    description = "The DEV public subnet id"
    value = aws_subnet.tst_public_subnet.id
}

output "prd_private_subnet_id" {
    description = "The PRD private subnet id"
    value = aws_subnet.prd_private_subnet.id
}

output "tst_private_subnet_id" {
    description = "The DEV private subnet id"
    value = aws_subnet.tst_private_subnet.id
}

output "nat_is_ready" {
    description = "The NAT GW is ready!"
    value = "${null_resource.nat_ready.id}"
}