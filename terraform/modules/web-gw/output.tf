output "web_gateway_ip" {
    description = "web_gateway_ip"
    value = aws_instance.web-gw.public_ip
}