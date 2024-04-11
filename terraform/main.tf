locals {

    name_prefix = "${var.owner}-${var.lab_name}-${var.loc_name}"
    hostname_prefix = "${var.lab_name}${var.loc_name}"
    domain_name = "acmesysinc.com"

    key_name   = "xshield-lab-builder-${var.owner}"
    owner_name = "xshield-lab-builder-${var.owner}"

    # VPC
    vpc_cidr_prefix = "10.0.10"

    # DMZ IPs
    dmz_public_subnet   = "${local.vpc_cidr_prefix}.0/28"
    upstream_dns_server = "${local.vpc_cidr_prefix}.2" 
    bastion_ip          = "${local.vpc_cidr_prefix}.4"
    siem_ip             = "${local.vpc_cidr_prefix}.5"
    asset_mgr_ip        = "${local.vpc_cidr_prefix}.6"
    vuln_scanner_ip     = "${local.vpc_cidr_prefix}.7"
    nat_gw_ip           = "${local.vpc_cidr_prefix}.8"

    # Prod Public IPs
    prd_public_subnet   = "${local.vpc_cidr_prefix}.16/28"
    prd_hrm_web_ip      = "${local.vpc_cidr_prefix}.20"
    prd_crm_web_ip      = "${local.vpc_cidr_prefix}.21"
    prd_wp_webapp_ip    = "${local.vpc_cidr_prefix}.22"

    # Dev Public IPs
    dev_public_subnet   = "${local.vpc_cidr_prefix}.32/28"
    dev_hrm_web_ip      = "${local.vpc_cidr_prefix}.36"
    dev_crm_web_ip      = "${local.vpc_cidr_prefix}.37"
    dev_wp_webapp_ip    = "${local.vpc_cidr_prefix}.38"

    # Prod Private IPs
    prd_private_subnet  = "${local.vpc_cidr_prefix}.64/27"
    prd_private_gw      = "${local.vpc_cidr_prefix}.65"   # Per AWS spec
    prd_hrm_app_ip      = "${local.vpc_cidr_prefix}.68"
    prd_hrm_db_ip       = "${local.vpc_cidr_prefix}.69"
    prd_crm_app_prefix  = "${local.vpc_cidr_prefix}.7"    # 70-79
    prd_crm_db_ip       = "${local.vpc_cidr_prefix}.80"
    prd_wp_db_ip        = "${local.vpc_cidr_prefix}.81"
    prd_gk_wan_ip       = "${local.vpc_cidr_prefix}.82"
    prd_fs_prefix       = "${local.vpc_cidr_prefix}.9"    # 90-94

    # Dev Private IPs
    dev_private_subnet  = "${local.vpc_cidr_prefix}.96/27"
    dev_hrm_app_ip      = "${local.vpc_cidr_prefix}.101"
    dev_hrm_db_ip       = "${local.vpc_cidr_prefix}.102"
    dev_wp_db_ip        = "${local.vpc_cidr_prefix}.103"
    dev_crm_db_ip       = "${local.vpc_cidr_prefix}.104"
    dev_crm_app_prefix  = "${local.vpc_cidr_prefix}.11"   # 110-119
    dev_fs_prefix       = "${local.vpc_cidr_prefix}.12"   # 120-126

    # Gatekeeper LAN IPs
    prd_gk_lan_subnet     = "${local.vpc_cidr_prefix}.128/27"
    prd_gk_lan_default_gw = "${local.vpc_cidr_prefix}.129" # Per AWS spec
    prd_gk_lan_ip         = "${local.vpc_cidr_prefix}.132"
    prd_gk_device_prefix  = "${local.vpc_cidr_prefix}.15" # 150-159


    prd_gk_lan_ip_nmask   = regex("/[0-9]+", local.prd_gk_lan_subnet)
    prd_gk_wan_ip_nmask   = regex("/[0-9]+", local.prd_private_subnet)
}

module "vpc" {
    source = "./modules/datacenter-in-a-box-vpc"
    
    name_prefix = local.name_prefix
    owner_name = local.owner_name

    dns_servers = [local.upstream_dns_server]
    domain_name = local.domain_name
    vpc_cidr_prefix = local.vpc_cidr_prefix
    nat_gw_ip = local.nat_gw_ip

    dmz_public_subnet = local.dmz_public_subnet
    prd_public_subnet = local.prd_public_subnet
    prd_private_subnet = local.prd_private_subnet
    dev_public_subnet = local.dev_public_subnet
    dev_private_subnet = local.dev_private_subnet
}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "!@#%&*-_=+<>:"
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
    Name = "${var.lab_name}-${var.loc_name}-DMZ-Public-IP"
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
    cidr_blocks = ["${local.vpc_cidr_prefix}.0/24"]
  }

  # Allow all external access, including Internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "public_ssh_sg" {
  name = "${var.lab_name}-${var.loc_name}-ext-ssh-sg"
  description = "Security group for External SSH access"
  vpc_id = module.vpc.vpc_id

  # Allow SSH 
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dmz_web_sg" {
  name = "${var.lab_name}-${var.loc_name}-dmz-web-sg"
  description = "Security group for External HTTP access"
  vpc_id = module.vpc.vpc_id

  # Allow HTTP 
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${aws_eip.bastion_eip.public_ip}/32"]
  }

  # Allow HTTPS
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${aws_eip.bastion_eip.public_ip}/32"]
  }
}

resource "aws_security_group" "public_web_sg" {
  name = "${var.lab_name}-${var.loc_name}-public-web-sg"
  description = "Security group for Public HTTP access"
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

  depends_on = [module.prd_crm.crm_public_ip, module.prd_hrm.hrm_public_ip,
                module.dev_crm.hrm_public_ip, module.dev_hrm.hrm_public_ip]

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  name_prefix = local.name_prefix 
  hostname_prefix = local.hostname_prefix
  dependency = module.vpc.nat_is_ready
  public_subnet_id = module.vpc.dmz_public_subnet_id
  eip_id = aws_eip.bastion_eip.id
  key_name = local.key_name

  bastion_ip = local.bastion_ip
  siem_ip = local.siem_ip
  asset_mgr_ip = local.asset_mgr_ip
  vuln_scanner_ip = local.vuln_scanner_ip
  
  internal_sg_id = aws_security_group.internal_sg.id
  public_ssh_sg_id = aws_security_group.public_ssh_sg.id

  resource_subnets = [local.prd_public_subnet, 
                      local.prd_private_subnet,
                      local.dev_public_subnet,
                      local.dev_private_subnet]
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name

  web_server_ip_list = [module.prd_crm.crm_public_ip, module.dev_crm.crm_public_ip,
                        module.prd_hrm.hrm_public_ip, module.dev_hrm.hrm_public_ip,
                        module.prd_wordpress.wordpress_public_ip, module.dev_wordpress.wordpress_public_ip]
}

module "prd_hrm" {

  source = "./modules/icehrm"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-prd-hrm"
  hostname_prefix = "${local.hostname_prefix}prdhrm"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.prd_private_subnet_id
  public_subnet_id = module.vpc.prd_public_subnet_id
  key_name = local.key_name

  web_ip = local.prd_hrm_web_ip
  app_ip = local.prd_hrm_app_ip
  db_ip = local.prd_hrm_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  dmz_web_sg_id = aws_security_group.dmz_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "dev_hrm" {

  source = "./modules/icehrm"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-dev-hrm"
  hostname_prefix = "${local.hostname_prefix}devhrm"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.dev_private_subnet_id
  public_subnet_id = module.vpc.dev_public_subnet_id
  key_name = local.key_name

  web_ip = local.dev_hrm_web_ip
  app_ip = local.dev_hrm_app_ip
  db_ip = local.dev_hrm_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  dmz_web_sg_id = aws_security_group.dmz_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "prd_crm" {

  source = "./modules/suitecrm"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-prd-crm"
  hostname_prefix = "${local.hostname_prefix}prdcrm"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.prd_private_subnet_id
  public_subnet_id = module.vpc.prd_public_subnet_id
  key_name = local.key_name

  app_server_count = 3

  web_ip = local.prd_crm_web_ip
  app_ip_prefix = local.prd_crm_app_prefix
  db_ip = local.prd_crm_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  dmz_web_sg_id = aws_security_group.dmz_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "dev_crm" {

  source = "./modules/suitecrm"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-dev-crm"
  hostname_prefix = "${local.hostname_prefix}devcrm"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.dev_private_subnet_id
  public_subnet_id = module.vpc.dev_public_subnet_id
  key_name = local.key_name

  app_server_count = 1

  web_ip = local.dev_crm_web_ip
  app_ip_prefix = local.dev_crm_app_prefix
  db_ip = local.dev_crm_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  dmz_web_sg_id = aws_security_group.dmz_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "prd_fs" {

  source = "./modules/fileshare"

  ami = data.aws_ami.win2019.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-prd-fs"
  hostname_prefix = "${local.hostname_prefix}prdfs"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.prd_private_subnet_id
  key_name = local.key_name

  fs_server_count = 2

  fs_ip_prefix = local.prd_fs_prefix
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_windows_pkg_url = var.xs_agent_windows_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "dev_fs" {

  source = "./modules/fileshare"

  ami = data.aws_ami.win2019.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-dev-fs"
  hostname_prefix = "${local.hostname_prefix}devfs"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.dev_private_subnet_id
  key_name = local.key_name

  fs_server_count = 1

  fs_ip_prefix = local.dev_fs_prefix
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_windows_pkg_url = var.xs_agent_windows_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "prd_wordpress" {

  source = "./modules/wordpress"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-prd-wp"
  hostname_prefix = "${local.hostname_prefix}prdwp"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.prd_private_subnet_id
  public_subnet_id = module.vpc.prd_public_subnet_id
  key_name = local.key_name

  webapp_ip = local.prd_wp_webapp_ip
  db_ip = local.prd_wp_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  public_web_sg_id = aws_security_group.public_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "dev_wordpress" {

  source = "./modules/wordpress"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  password = random_password.password.result
  name_prefix = "${local.name_prefix}-dev-wp"
  hostname_prefix = "${local.hostname_prefix}devwp"
  dependency = module.vpc.nat_is_ready
  private_subnet_id = module.vpc.dev_private_subnet_id
  public_subnet_id = module.vpc.dev_public_subnet_id
  key_name = local.key_name

  webapp_ip = local.dev_wp_webapp_ip
  db_ip = local.dev_wp_db_ip
  siem_ip = local.siem_ip
  assetmgr_ip = local.asset_mgr_ip
  xs_domain = var.xs_domain
  xs_deployment_key = var.xs_deployment_key
  xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url

  internal_sg_id = aws_security_group.internal_sg.id
  public_web_sg_id = aws_security_group.public_web_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "gatekeeper" {

  source = "./modules/gatekeeper"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  name_prefix = "${local.name_prefix}-gk"
  hostname_prefix = "${local.hostname_prefix}gk"
  dependency = module.vpc.nat_is_ready
  vpc_id = module.vpc.vpc_id
  key_name = local.key_name

  gk_lan_ip = local.prd_gk_lan_ip
  gk_lan_ip_nmask = local.prd_gk_lan_ip_nmask
  gk_lan_gw = local.prd_gk_lan_ip

  gk_wan_ip = local.prd_gk_wan_ip
  gk_wan_ip_nmask = local.prd_gk_wan_ip_nmask
  gk_wan_gw = local.prd_private_gw

  xs_gatekeeper_pkg_url = var.xs_gatekeeper_pkg_url
  xs_deployment_key = var.xs_deployment_key
  xs_domain = var.xs_domain

  gk_lan_subnet = local.prd_gk_lan_subnet
  gk_wan_subnet_id = module.vpc.prd_private_subnet_id

  internal_sg_id = aws_security_group.internal_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

module "agentless_devices" {

  source = "./modules/devices"

  ami = data.aws_ami.ubuntu_22_04.id
  owner_name = local.owner_name
  name_prefix = "${local.name_prefix}-gk"
  hostname_prefix = "${local.hostname_prefix}gk"
  dependency = module.vpc.nat_is_ready
  key_name = local.key_name

  gk_lan_subnet_id = module.gatekeeper.gk_lan_subnet_id
  device_ip_prefix = local.prd_gk_device_prefix
  device_count = 3
  gk_lan_ip = local.prd_gk_lan_ip
  gk_lan_default_gw = local.prd_gk_lan_default_gw

  internal_sg_id = aws_security_group.internal_sg.id
  ssm_instance_profile_name = aws_iam_instance_profile.ssm_instance_profile.name
}

