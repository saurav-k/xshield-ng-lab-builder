resource "aws_instance" "fileshare" {
  ami               = var.ami
  instance_type     = "t3.small"
  count             = var.fs_server_count
  key_name          = var.key_name
  subnet_id         = var.private_subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = "${var.fs_ip_prefix}${count.index+1}"
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-${count.index+1}"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("", [
      templatefile("${path.module}/user_data_templates/fs_user_data.ps1",
        {   hostname = "${var.hostname_prefix}${count.index+1}",
            password = var.password,
        }),
      templatefile("${path.root}/common_user_data_templates/windows_agents.ps1",
        {  
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip,
            xs_agent_windows_pkg_url = var.xs_agent_windows_pkg_url,
            xs_domain = var.xs_domain,
            xs_deployment_key = var.xs_deployment_key
        })
      ]
    ))
}