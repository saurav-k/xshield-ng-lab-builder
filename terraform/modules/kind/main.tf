resource "aws_instance" "kind" {
  ami                           = var.ami
  instance_type                 = "t3.xlarge"
  key_name                      = var.key_name
  subnet_id                     = var.subnet_id
  vpc_security_group_ids        = var.security_group_ids
  private_ip                    = var.kind_ip
  iam_instance_profile          = var.ssm_instance_profile_name
  associate_public_ip_address   = true
  source_dest_check             = false

  tags = {
    Name = "${var.name_prefix}"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/kind_user_data.sh",
        {   
          hostname = var.hostname_prefix,
          xs_container_agent_version = var.xs_container_agent_version,
          xs_container_registry_uri = var.xs_container_registry_uri,
          xs_deployment_key = var.xs_deployment_key,
          xs_domain = var.xs_domain
          web_gw_ip = var.web_gw_ip
        }))
}