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

variable "dmz_public_subnet" {
    description = "The CIDR block for the DMZ public subnet"
    type = string
}

variable "prd_public_subnet" {
    description = "The CIDR block for the Prod public subnet"
    type = string 
}

variable "prd_private_subnet" {
    description = "The CIDR block for the Prod private subnet"
    type = string 
}

variable "tst_public_subnet" {
    description = "The CIDR block for the Prod public subnet"
    type = string 
}

variable "tst_private_subnet" {
    description = "The CIDR block for the Prod private subnet"
    type = string 
}