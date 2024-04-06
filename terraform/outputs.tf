output "bastion_ip" {
    description = "Public IP of the Bastion"
    value = aws_eip.bastion_eip.public_ip
}

output "pem" {
    description = "SSH PEM Filename"
    value = "${path.cwd}/${local_file.ssh_pem_file.filename}"
}

output "wordpress_prd_url" {
    description = "Wordpress Prod URL"
    value = "https://${module.prd_wordpress.wordpress_public_ip}"
}

output "wordpress_dev_url" {
    description = "Wordpress Dev URL"
    value = "https://${module.dev_wordpress.wordpress_public_ip}"
}

output "password" {
    description = "Password for Windows VMs, databases and applications"
    value = random_password.password.result
    sensitive = true
}