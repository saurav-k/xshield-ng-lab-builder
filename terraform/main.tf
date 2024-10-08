locals {

    aws_region = "us=east-1"
    name_prefix = "${var.owner}-${var.lab_name}-${var.loc_name}"
    bucket_name_prefix = "${var.bucket_owner}-${var.lab_name}-${var.loc_name}"
    #hostname_prefix = "${var.lab_name}${var.loc_name}"
    hostname_prefix = "${var.loc_name}"
    domain_name = "acmesysinc.com"

    key_name   = "xshield-lab-builder-${var.owner}"
    owner_name = "xshield-lab-builder-${var.owner}"

    # VPC
    vpc_cidr_prefix = "10.0"

    # Subnets
    public_subnet_prefix  = "${local.vpc_cidr_prefix}.10"
    public_subnet_cidr    = "${local.public_subnet_prefix}.0/28"

    private_subnet_prefix = "${local.vpc_cidr_prefix}.20"
    private_subnet_cidr   = "${local.private_subnet_prefix}.0/26"

    gk_subnet_prefix      = "${local.vpc_cidr_prefix}.30"
    gk_subnet_cidr        = "${local.gk_subnet_prefix}.0/24"

    # AWS IPs
    upstream_dns_server   = "${local.vpc_cidr_prefix}.0.2"
    aws_nat_gw_ip         = "${local.public_subnet_prefix}.4"

    # Infra - DMZ Gateway
    web_gw_ip             = "${local.public_subnet_prefix}.5"     # Gateway for all web servers and K8s

    # Infra - Multipurpose Server (has 4 interfaces)
    bastion_ip            = "${local.public_subnet_prefix}.6"      # Multipurpose VM 1 Intf 1
    siem_ip               = "${local.public_subnet_prefix}.7"      # Multipurpose VM 1 Intf 2
    asset_mgr_ip          = "${local.public_subnet_prefix}.8"      # Multipurpose VM 1 Intf 3
    vuln_scanner_ip       = "${local.public_subnet_prefix}.9"      # Multipurpose VM 1 Intf 4

    # Kubernetes cluster
    kind_ip               = "${local.public_subnet_prefix}.10"
    
    # HRM IPs
    prd_hrm_web_ip        = "${local.private_subnet_prefix}.4"
    prd_hrm_app_ip        = "${local.private_subnet_prefix}.5"
    prd_hrm_db_ip         = "${local.private_subnet_prefix}.6"
    tst_hrm_web_ip        = "${local.private_subnet_prefix}.7"
    tst_hrm_app_ip        = "${local.private_subnet_prefix}.8"
    tst_hrm_db_ip         = "${local.private_subnet_prefix}.9"

    # CRM IPs
    prd_crm_web_ip        = "${local.private_subnet_prefix}.10"
    prd_crm_app_prefix    = "${local.private_subnet_prefix}.1"    # 11-18
    prd_crm_db_ip         = "${local.private_subnet_prefix}.19"
    tst_crm_web_ip        = "${local.private_subnet_prefix}.20"
    tst_crm_app_prefix    = "${local.private_subnet_prefix}.2"    # 21-28
    tst_crm_db_ip         = "${local.private_subnet_prefix}.29"

    # Portal IPs
    prd_wp_webapp_ip      = "${local.private_subnet_prefix}.30"
    prd_wp_db_ip          = "${local.private_subnet_prefix}.31"
    tst_wp_webapp_ip      = "${local.private_subnet_prefix}.32"
    tst_wp_db_ip          = "${local.private_subnet_prefix}.33"

    # File servers
    prd_fs_prefix         = "${local.private_subnet_prefix}.4"    # 41-49
    tst_fs_prefix         = "${local.private_subnet_prefix}.5"    # 50-59

    # Gatekeeper - WAN side
    private_subnet_gw     = "${local.private_subnet_prefix}.1"   # Per AWS spec
    prd_gk_wan_ip         = "${local.private_subnet_prefix}.60"
    prd_gk_wan_ip_nmask   = regex("/[0-9]+", local.private_subnet_cidr)

    # Gatekeeper - LAN side
    prd_gk_lan_default_gw = "${local.gk_subnet_prefix}.1" # Per AWS spec
    prd_gk_lan_ip         = "${local.gk_subnet_prefix}.4"
    prd_gk_device_prefix  = "${local.gk_subnet_prefix}.1" # 11-19
    prd_gk_device_count   = 3
    prd_gk_lan_ip_nmask   = regex("/[0-9]+", local.gk_subnet_cidr)

    # Webstore Istio Ingress
    webstore_ip           = "172.20.255.210"
}

module "vpc" {
    source = "./modules/datacenter-in-a-box-vpc"
    
    name_prefix = local.name_prefix
    owner_name = local.owner_name

    dns_servers = [local.upstream_dns_server]
    domain_name = local.domain_name
    vpc_cidr_prefix = local.vpc_cidr_prefix
    nat_gw_ip = local.aws_nat_gw_ip

    public_subnet = local.public_subnet_cidr
    private_subnet = local.private_subnet_cidr
}

module "vpc-logs-to-s3" {
    source = "./modules/vpc-logs-to-s3"
    name_prefix       = local.name_prefix
    owner_name        = local.owner_name
    aws_region        = local.aws_region
    bucket_name_prefix = local.bucket_name_prefix
}

# module "vpc" {
#     source = "./modules/vpc-logs-to-s3"
    
#     name_prefix = local.name_prefix
#     owner_name = local.owner_name

#     dns_servers = [local.upstream_dns_server]
#     domain_name = local.domain_name
#     vpc_cidr_prefix = local.vpc_cidr_prefix
#     nat_gw_ip = local.aws_nat_gw_ip

#     public_subnet = local.public_subnet_cidr
#     private_subnet = local.private_subnet_cidr
# }

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "+-_@#!"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = local.key_name
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "ssh_pem_file" {
  filename = "${local.owner_name}.pem"
  content = tls_private_key.private_key.private_key_pem
  file_permission = "0600"
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.lab_name}-${var.loc_name}-Bastion-Public-IP"
  }
}

resource "aws_eip" "web_gw_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.lab_name}-${var.loc_name}-Web-GW-Public-IP"
  }
}

resource "aws_security_group" "internal_sg" {
  name = "${var.lab_name}-${var.loc_name}-internal-sg"
  description = "Security group for Internal Access"
  vpc_id = module.vpc.vpc_id

  # Allow all internal access 
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${local.vpc_cidr_prefix}.0.0/16"]
  }

  # Allow all external access, including Internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion_sg" {
  name = "${var.lab_name}-${var.loc_name}-bastion-sg"
  description = "Security group for the Bastion"
  vpc_id = module.vpc.vpc_id

  # Allow SSH 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_gw_sg" {
  name = "${var.lab_name}-${var.loc_name}-web-gw-sg"
  description = "Security group for the DMZ Web gateway"
  vpc_id = module.vpc.vpc_id

  # Allow HTTP 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ssm_access_role" {
  name = "ssm-role-${local.owner_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    owner = local.owner_name
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role = aws_iam_role.ssm_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${local.owner_name}-ssm_instance_profile"
  role = aws_iam_role.ssm_access_role.name
}

module "infra" {

  source = "./modules/infra"

  # depends_on = [
  #     module.prd_crm.crm_public_ip, module.prd_hrm.hrm_public_ip, module.prd_portal.portal_public_ip,
  #     module.tst_crm.crm_public_ip, module.tst_hrm.hrm_public_ip, module.tst_portal.portal_public_ip
  #   ]

    depends_on = [
      module.prd_crm.crm_public_ip,
    ]

    # depends_on = [
    #   module.prd_crm.crm_public_ip,
    #   module.tst_crm.crm_public_ip
    # ]

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  name_prefix = local.name_prefix 
  hostname_prefix = local.hostname_prefix
  dependency = module.vpc.nat_is_ready
  public_subnet_id = module.vpc.public_subnet_id
  eip_id = aws_eip.bastion_eip.id
  key_name = local.key_name

  bastion_ip = local.bastion_ip
  siem_ip = local.siem_ip
  asset_mgr_ip = local.asset_mgr_ip
  vuln_scanner_ip = local.vuln_scanner_ip
  
  security_group_ids = [aws_security_group.bastion_sg.id, aws_security_group.internal_sg.id]

  resource_subnets = [local.public_subnet_cidr, 
                      local.private_subnet_cidr]
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "web_gw" {

  source = "./modules/web-gw"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  name_prefix = local.name_prefix 
  hostname_prefix = local.hostname_prefix
  dependency = module.vpc.nat_is_ready
  subnet_id = module.vpc.public_subnet_id
  eip_id = aws_eip.web_gw_eip.id
  eip = aws_eip.web_gw_eip.public_ip

  prd_crm_ip = local.prd_crm_web_ip
  prd_hrm_ip = local.prd_hrm_web_ip
  prd_portal_ip = local.prd_wp_webapp_ip
  webstore_ip = local.webstore_ip
  kind_ip = local.kind_ip

  key_name = local.key_name

  web_gw_ip =  local.web_gw_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip

  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  security_group_ids = [aws_security_group.web_gw_sg.id, aws_security_group.internal_sg.id]

  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

# module "prd_hrm" {

#   source = "./modules/icehrm"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-prd-hrm"
#   hostname_prefix = "${local.hostname_prefix}prdhrm"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   web_ip = local.prd_hrm_web_ip
#   app_ip = local.prd_hrm_app_ip
#   db_ip = local.prd_hrm_db_ip
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "tst_hrm" {

#   source = "./modules/icehrm"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-tst-hrm"
#   hostname_prefix = "${local.hostname_prefix}tsthrm"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   web_ip = local.tst_hrm_web_ip
#   app_ip = local.tst_hrm_app_ip
#   db_ip = local.tst_hrm_db_ip
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

module "prd_crm" {

  source = "./modules/suitecrm"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-prd-crm"
  hostname_prefix = "${local.hostname_prefix}prdcrm"
  dependency = module.vpc.nat_is_ready
  subnet_id = module.vpc.private_subnet_id
  key_name = local.key_name

  app_server_count = 1 # changed to 1 from 3 

  web_ip = local.prd_crm_web_ip
  app_ip_prefix = local.prd_crm_app_prefix
  db_ip = local.prd_crm_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url
  legacy_db_ip_prefix = local.prd_gk_device_prefix
  legacy_db_count = local.prd_gk_device_count

  internal_sg_id = aws_security_group.internal_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

# module "tst_crm" {

#   source = "./modules/suitecrm"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-tst-crm"
#   hostname_prefix = "${local.hostname_prefix}tstcrm"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   app_server_count = 1

#   web_ip = local.tst_crm_web_ip
#   app_ip_prefix = local.tst_crm_app_prefix
#   db_ip = local.tst_crm_db_ip
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url
#   legacy_db_ip_prefix = local.prd_gk_device_prefix
#   legacy_db_count = local.prd_gk_device_count

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "prd_fs" {

#   source = "./modules/fileshare"

#   ami = data.aws_ami.win2019.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-prd-fs"
#   hostname_prefix = "${local.hostname_prefix}prdfs"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   fs_server_count = 2

#   fs_ip_prefix = local.prd_fs_prefix
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_windows_pkg_url = var.xs_agent_windows_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "tst_fs" {

#   source = "./modules/fileshare"

#   ami = data.aws_ami.win2019.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-tst-fs"
#   hostname_prefix = "${local.hostname_prefix}tstfs"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   fs_server_count = 1

#   fs_ip_prefix = local.tst_fs_prefix
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_windows_pkg_url = var.xs_agent_windows_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "prd_portal" {

#   source = "./modules/wordpress"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-prd-prtl"
#   hostname_prefix = "${local.hostname_prefix}prdprtl"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   webapp_ip = local.prd_wp_webapp_ip
#   db_ip = local.prd_wp_db_ip
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "tst_portal" {

#   source = "./modules/wordpress"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   password = random_password.password.result
#   name_prefix = "${local.name_prefix}-tst-prtl"
#   hostname_prefix = "${local.hostname_prefix}tstprtl"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.private_subnet_id
#   key_name = local.key_name

#   webapp_ip = local.tst_wp_webapp_ip
#   db_ip = local.tst_wp_db_ip
#   siem_ip = local.siem_ip
#   assetmgr_ip = local.asset_mgr_ip
#   xs_domain = var.xs_domain
#   xs_deployment_key = var.xs_deployment_key
#   xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "kind" {

#   source = "./modules/kind"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   name_prefix = "${local.name_prefix}-prd-kind"
#   hostname_prefix = "${local.hostname_prefix}prdkind"
#   dependency = module.vpc.nat_is_ready
#   subnet_id = module.vpc.public_subnet_id
#   key_name = local.key_name

#   xs_container_agent_version = var.xs_container_agent_version
#   xs_container_registry_uri = var.xs_container_registry_uri
#   xs_deployment_key = var.xs_deployment_key
#   xs_domain = var.xs_domain
#   web_gw_ip = local.web_gw_ip

#   kind_ip = local.kind_ip
#   security_group_ids = [aws_security_group.internal_sg.id, aws_security_group.bastion_sg.id]

#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "gatekeeper" {

#   source = "./modules/gatekeeper"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   name_prefix = "${local.name_prefix}-gk"
#   hostname_prefix = "${local.hostname_prefix}gx"
#   dependency = module.vpc.nat_is_ready
#   vpc_id = module.vpc.vpc_id
#   key_name = local.key_name

#   gk_lan_ip = local.prd_gk_lan_ip
#   gk_lan_ip_nmask = local.prd_gk_lan_ip_nmask
#   gk_lan_gw = local.prd_gk_lan_ip

#   gk_wan_ip = local.prd_gk_wan_ip
#   gk_wan_ip_nmask = local.prd_gk_wan_ip_nmask
#   gk_wan_gw = local.private_subnet_gw

#   xs_gatekeeper_pkg_url = var.xs_gatekeeper_pkg_url
#   xs_deployment_key = var.xs_deployment_key
#   xs_domain = var.xs_domain

#   gk_lan_subnet = local.gk_subnet_cidr
#   gk_wan_subnet_id = module.vpc.private_subnet_id

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# module "agentless_devices" {

#   source = "./modules/devices"

#   ami = data.aws_ami.ubuntu_22_04.id
#   owner_name = local.owner_name
#   name_prefix = "${local.name_prefix}-gk"
#   hostname_prefix = "${local.hostname_prefix}gk"
#   dependency = module.vpc.nat_is_ready
#   key_name = local.key_name

#   gk_lan_subnet_id = module.gatekeeper.gk_lan_subnet_id
#   device_ip_prefix = local.prd_gk_device_prefix
#   device_count = local.prd_gk_device_count
#   gk_lan_ip = local.prd_gk_lan_ip
#   gk_lan_default_gw = local.prd_gk_lan_default_gw

#   internal_sg_id = aws_security_group.internal_sg.id
#   ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
# }

# resource "aws_route" "gk_devices_route" {
#   route_table_id         = module.vpc.private_subnet_rt_id
#   destination_cidr_block = local.gk_subnet_cidr
#   network_interface_id   = module.gatekeeper.gk_wan_interface_id
# }