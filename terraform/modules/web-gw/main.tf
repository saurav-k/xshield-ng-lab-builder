resource "aws_instance" "web-gw" {
  ami               = var.ami
  instance_type     = "t3.micro"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  private_ip        = var.web_gw_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-web-gw"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/web_gw_user_data.sh",
        {
          hostname = "${var.hostname_prefix}webgw",
          my_public_ip = var.eip
          prd_crm_ip = var.prd_crm_ip
          prd_hrm_ip = var.prd_hrm_ip
          prd_portal_ip = var.prd_portal_ip
          webstore_ip = var.webstore_ip
          kind_ip = var.kind_ip
        }),
      templatefile("${path.root}/common_user_data_templates/debian_agents.sh",
        {  
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip,
            xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url,
            xs_domain = var.xs_domain,
            xs_deployment_key = var.xs_deployment_key
        })
      ]
    ))
}

resource "aws_eip_association" "web_gw_eip_association" {
  instance_id = aws_instance.web-gw.id
  allocation_id = var.eip_id
}