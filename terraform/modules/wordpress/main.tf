resource "aws_instance" "db" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  subnet_id         = var.private_subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = var.db_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-db"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/db_user_data.sh",
        {   hostname = "${var.hostname_prefix}db",
            password = var.password,
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip
        }))
}

resource "aws_instance" "webapp" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  subnet_id         = var.public_subnet_id
  vpc_security_group_ids = [var.internal_sg_id, var.public_web_sg_id]
  private_ip        = var.webapp_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-webapp"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/webapp_user_data.sh",
        {   hostname = "${var.hostname_prefix}webapp",
            password = var.password,
            db_ip = var.db_ip,
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip
        }))
}