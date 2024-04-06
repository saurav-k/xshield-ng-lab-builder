output "crm_public_ip" {
    description = "Public IP address of the CRM Webserver"
    value = aws_instance.web.public_ip
}