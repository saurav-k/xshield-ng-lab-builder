output "bastion_public_ip" {
    description = "Bastion Public IP"
    value = aws_eip.bastion_eip.public_ip
}

output "bastion_ip" {
    description = "Bastion IP"
    value = local.bastion_ip
}

output "asset_mgr_ip" {
    description = "Asset Manager IP"
    value = local.asset_mgr_ip
}

output "vuln_scanner_ip" {
    description = "Vuln Scanner IP"
    value = local.vuln_scanner_ip
}

output "siem_ip" {
    description = "SIEM IP"
    value = local.siem_ip
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