output "wordpress_public_ip" {
    description = "Public IP address of the Wordpress site"
    value = aws_instance.webapp.public_ip
}