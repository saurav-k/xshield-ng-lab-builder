output "gk_lan_subnet_id" {
    description = "The Gatekeeper LAN subnet id"
    value = aws_subnet.gk_lan_subnet.id
}

output "gk_wan_interface_id" {
    description = "The Gatekeeper WAN interface id"
    value = aws_network_interface.gk_wan_interface.id
}