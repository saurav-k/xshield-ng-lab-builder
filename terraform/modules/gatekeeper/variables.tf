variable "key_name" {
    description = "Key name for instance creation"
    type = string
}

variable "owner_name" {
    description = "The owner of the VPC.  The 'Owner' tag will be set to this value"
    type = string
}

variable "vpc_id" {
    description = "VPC Id"
    type = string
}

variable "name_prefix" {
    description = "Prefix for the resource name"
    type = string
}

variable "hostname_prefix" {
    description = "Prefix for the host name"
    type = string
}

variable "gk_lan_subnet" {
    description = "The CIDR block for the Gatekeeper's LAN subnet"
    type = string 
}

variable "gk_wan_subnet_id" {
    description = "The subnet Id of the Gatekeeper WAN subnet"
    type = string 
}

variable "gk_wan_ip" {
    description = "Gatekeeper WAN IP"
    type = string 
}

variable "gk_wan_gw" {
    description = "Gatekeeper WAN Gateway"
    type = string 
}

variable "gk_lan_ip" {
    description = "Gatekeeper LAN IP"
    type = string
}

variable "gk_lan_gw" {
    description = "Gatekeeper LAN Gateway"
    type = string 
}

variable "gk_wan_ip_nmask" {
    description = "Netmask for the Gatekeeper WAN IP"
    type = string
}

variable "gk_lan_ip_nmask" {
    description = "Netmask for the Gatekeeper LAN IP"
    type = string
}

variable "xs_gatekeeper_pkg_url" {
    description = "Gatekeeper package URL"
    type = string
}

variable "xs_domain" {
    description = "Xshield domain (URL)"
    type = string
}

variable "xs_deployment_key" {
    description = "Xshield deployment key"
    type = string
}

variable "dependency" {
    description = "Dummy variable for dependency"
    type = string
}

variable "internal_sg_id" {
    description = "Internal security group Id"
    type = string
}

variable "ssm_instance_profile_name" {
    description = "Instance profile name for SSM"
    type = string
}

variable "ami" {
    description = "Base AMI"
    type = string
}
