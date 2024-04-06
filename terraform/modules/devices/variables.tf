variable "key_name" {
    description = "Key name for instance creation"
    type = string
}

variable "owner_name" {
    description = "The owner of the VPC.  The 'Owner' tag will be set to this value"
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

variable "gk_lan_subnet_id" {
    description = "The id of the Gatekeeper LAN subnet"
    type = string 
}

variable "device_ip_prefix" {
    description = "Prefix of IP addresses for the (virtual) devices"
    type = string
}

variable "device_count" {
    description = "Number of devices"
    type = number
}

variable "gk_lan_ip" {
    description = "Lan IP of the Gatekeeper"
    type = string
}

variable "gk_lan_default_gw" {
    description = "Default GW of the Gatekeeper's LAN"
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
