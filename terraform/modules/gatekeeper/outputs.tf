output "gk_lan_subnet_id" {
    description = "The Gatekeeper LAN subnet id"
    value = aws_subnet.gk_lan_subnet.id
}