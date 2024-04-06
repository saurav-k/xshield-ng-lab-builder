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

variable "public_subnet_id" {
    description = "Public subnet id for the Bastion"
    type = string
}

variable "resource_subnets" {
  description = "The prod and dev subnets"
  type = list(string)
}

variable "dependency" {
    description = "Dummy variable for dependency"
    type = string
}

variable "internal_sg_id" {
    description = "Internal security group Id"
    type = string
}

variable "public_ssh_sg_id" {
    description = "Public SSH security group Id"
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

variable "web_server_ip_list" {
    description = "List of web servers to generate traffic to"
    type = list(string)
}

variable "eip_id" {
    description = "Elastic IP id for the Bastion"
    type = string
}

variable "bastion_ip" {
    description = "Bastion IP"
    type = string
}

variable "siem_ip" {
    description = "SIEM IP"
    type = string
}

variable "asset_mgr_ip" {
    description = "Asset Manager IP"
    type = string
}

variable "vuln_scanner_ip" {
    description = "Vulnerability Scanner IP"
    type = string
}
