# Wants - vpc_id, internal_sg, gk_lan_subnet, gk_lan_ip, gk_wan_subnet_id, gk_wan_ip
# Outputs - gk_lan_subnet_id

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# Gatekeeper LAN subnet
resource "aws_subnet" "gk_lan_subnet" {

  vpc_id            = var.vpc_id
  cidr_block        = var.gk_lan_subnet
  availability_zone = data.aws_availability_zones.available.names.0

  tags = {
    Name = "${var.name_prefix}-lan-subnet"
  }
}

# Gatekeeper LAN interface
resource "aws_network_interface" "gk_lan_interface" {
  
  subnet_id        = aws_subnet.gk_lan_subnet.id
  private_ips      = [var.gk_lan_ip]
  security_groups = [var.internal_sg_id]
  source_dest_check = false
  tags = {
    Name = "${var.name_prefix}-lan"
  }
}

# Gatekeeper WAN interface
resource "aws_network_interface" "gk_wan_interface" {
  
  subnet_id        = var.gk_wan_subnet_id
  private_ips      = [var.gk_wan_ip]
  security_groups = [var.internal_sg_id]
  source_dest_check = false
  tags = {
    Name = "${var.name_prefix}-wan"
  }
}

# Gatekeeper LAN route table
# Send all traffic to the Gatekeeper's LAN interface
# Note that AWS will still send local traffic (like 10.0.0.0/16) to the AWS router,
# so we will need to add explicit routes on each agent-less device.
resource "aws_route_table" "rt_gk_lan" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    network_interface_id = aws_network_interface.gk_lan_interface.id
  }

  tags = {
    Name = "${var.name_prefix}-lan-rt"
  }
}

# Gatekeeper LAN subnet --> Gatekeeper Route Table association
resource "aws_route_table_association" "assoc_rt_gk_lan_gk_subnet" {

  subnet_id       = aws_subnet.gk_lan_subnet.id
  route_table_id  = aws_route_table.rt_gk_lan.id
}

resource "aws_instance" "gatekeeper-pri" {
  ami               = var.ami
  instance_type     = "t3.small"
  key_name          = var.key_name
  iam_instance_profile = var.ssm_instance_profile_name
  
  network_interface {
    device_index            = 0
    network_interface_id    = aws_network_interface.gk_wan_interface.id
  }

  network_interface {
    device_index             = 1
    network_interface_id    = aws_network_interface.gk_lan_interface.id
  }

  tags = {
    Name = "${var.name_prefix}-pri"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(templatefile("${path.module}/user_data_templates/gatekeeper_user_data.sh",
        {   
          hostname = "${var.hostname_prefix}pri",
          gk_wan_ip = "${var.gk_wan_ip}${var.gk_wan_ip_nmask}",
          gk_wan_gw = var.gk_wan_gw,
          gk_lan_ip = "${var.gk_lan_ip}${var.gk_lan_ip_nmask}",
          gk_lan_gw = var.gk_lan_ip,
          gk_pkg_url = var.xs_gatekeeper_pkg_url,
          xs_domain = var.xs_domain,
          xs_deployment_key = var.xs_deployment_key
        }))
}







