resource "aws_instance" "db" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = var.db_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-db"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/db_user_data.sh",
        {   hostname = "${var.hostname_prefix}db",
            password = var.password,            
            legacy_db_ip_prefix = var.legacy_db_ip_prefix,
            legacy_db_count = var.legacy_db_count
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

resource "aws_instance" "app" {
  count             = var.app_server_count
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = "${var.app_ip_prefix}${count.index+1}"
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-app-${count.index+1}"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/app_user_data.sh",
        {   hostname = "${var.hostname_prefix}app${count.index+1}",
            password = var.password,
            db_ip = var.db_ip,
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

resource "aws_instance" "web" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = var.web_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-web"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/web_user_data.sh",
        {   hostname = "${var.hostname_prefix}web",
            app_ip_prefix = var.app_ip_prefix,
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