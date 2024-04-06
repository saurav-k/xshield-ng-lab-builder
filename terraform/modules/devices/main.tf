resource "aws_instance" "agentless-devices" {
  ami               = var.ami
  instance_type     = "t3.nano"
  key_name          = var.key_name
  iam_instance_profile = var.ssm_instance_profile_name
  count             = var.device_count

  subnet_id         = var.gk_lan_subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = "${var.device_ip_prefix}${count.index+1}"

  tags = {
    Name = "${var.name_prefix}-device-${count.index+1}"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/devices_user_data.sh",
        {   
          hostname = "${var.hostname_prefix}device${count.index+1}",
          gk_lan_ip = "${var.gk_lan_ip}"
          gk_lan_default_gw = "${var.gk_lan_default_gw}"
        }))
}
