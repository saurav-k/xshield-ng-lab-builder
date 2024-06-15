# A VPC with one public subnet and two private subnets

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# VPC

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name_servers = var.dns_servers
  domain_name = var.domain_name

  tags = {
    Name = "${var.name_prefix}-dhcp-opts"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block       = "${var.vpc_cidr_prefix}.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "${var.name_prefix}-vpc"
    Owner = var.owner_name
  }
  enable_dns_hostnames = true
}

resource "aws_vpc_dhcp_options_association" "dhcp_opts_assoc" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

# Public subnets

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_1
  availability_zone = data.aws_availability_zones.available.names.0
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-subne-1"
  }
}

# End of Public subnets

# Private subnets
resource "aws_subnet" "private_subnet_1" {

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_1
  availability_zone = data.aws_availability_zones.available.names.0

  tags = {
    Name = "${var.name_prefix}-private-subnet-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix}-internet-gateway"
  }
}

# Route table towards Internet Gateway
resource "aws_route_table" "rt_igw" {

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.name_prefix}-igw-rt"
  }
}

# Public subnet --> IGW association
resource "aws_route_table_association" "assoc_rt_igw_public" {

  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.rt_igw.id
}

# Elastic IP for NATGW
resource "aws_eip" "natgw_eip" {

  tags = {
    Name = "${var.name_prefix}-natgw-eip"
  }
}

# NAT gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  private_ip    = var.nat_gw_ip

  tags = {
    Name = "${var.name_prefix}-nat-gateway"
  }
}

# Dummy dependency for EC2 instances on NAT gateway
resource "null_resource" "nat_ready" {
  depends_on = [aws_nat_gateway.natgw]
}

# Route table towards NAT gateway
resource "aws_route_table" "rt_nat_gw" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "${var.name_prefix}-natgw-rt"
  }
}

# Private subnets --> NATGW association
resource "aws_route_table_association" "assoc_rt_natgw_private_1" {

  subnet_id       = aws_subnet.private_subnet_1.id
  route_table_id  = aws_route_table.rt_nat_gw.id
}