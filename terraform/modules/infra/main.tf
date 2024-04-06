resource "aws_network_interface" "eni1" {
  subnet_id        = var.public_subnet_id
  private_ip_list_enabled = true
  private_ip_list = [var.bastion_ip, var.siem_ip, var.asset_mgr_ip, var.vuln_scanner_ip]
  security_groups = [var.internal_sg_id, var.public_ssh_sg_id]
  tags = {
    Name = "${var.name_prefix}-bastion-en1"
  }
}

resource "aws_instance" "bastion" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  iam_instance_profile = var.ssm_instance_profile_name
  
  network_interface {
      device_index            = 0
      network_interface_id    = "${aws_network_interface.eni1.id}"
    }

  tags = {
    Name = "${var.name_prefix}-bastion"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/bastion_user_data.sh",
        {   hostname = "${var.hostname_prefix}bastion",
            nmap_subnets = join(" ", var.resource_subnets),
            siem_ip = var.siem_ip,
            asset_mgr_ip = var.asset_mgr_ip,
            vuln_scanner_ip = var.vuln_scanner_ip
            web_server_ip_list = join("\n", var.web_server_ip_list)
        }))
}

resource "aws_eip_association" "bastion_eip_association" {
  instance_id = aws_instance.bastion.id
  allocation_id = var.eip_id
}