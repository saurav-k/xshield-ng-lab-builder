output "hrm_public_ip" {
    description = "Public IP address of the HRM Webserver"
    value = aws_instance.web.public_ip
}