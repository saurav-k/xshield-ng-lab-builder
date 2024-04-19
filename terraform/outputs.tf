output "bastion_ip" {
    description = "Public IP of the Bastion"
    value = aws_eip.bastion_eip.public_ip
}

output "pem" {
    description = "SSH PEM Filename"
    value = "${path.cwd}/${local_file.ssh_pem_file.filename}"
}

output "portal_prd_url" {
    description = "Portal Prod URL"
    value = "https://${module.prd_portal.wordpress_public_ip}"
}

output "portal_tst_url" {
    description = "Portal Test URL"
    value = "https://${module.tst_portal.wordpress_public_ip}"
}

output "password" {
    description = "Password for Windows VMs, databases and applications"
    value = random_password.password.result
    sensitive = true
}