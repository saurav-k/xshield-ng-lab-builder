variable "dns_servers" {
    description = "DNS servers for this VPC"
    type = list(string)
}

variable "domain_name" {
    description = "Domain name"
    type = string
}

variable "name_prefix" {
    description = "A name that will be used as a prefix while creating objects"
    type = string
}

variable "owner_name" {
    description = "The owner of the VPC.  The 'Owner' tag will be set to this value"
    type = string
}

variable "vpc_cidr_prefix" {
    description = "The CIDR prefix for the VPC"
    type = string
}

variable "nat_gw_ip" {
    description = "NAT GW Private IP"
    type = string
}

variable "public_subnet" {
    description = "The CIDR block for the public subnet"
    type = string
}

variable "private_subnet_2" {
    description = "The CIDR block for the private_subnet_2"
    type = string 
}

variable "private_subnet" {
    description = "The CIDR block for the private subnet"
    type = string 
}