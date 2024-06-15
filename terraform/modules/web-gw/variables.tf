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

variable "subnet_id" {
    description = "Subnet id for the servers"
    type = string
}

variable "web_gw_ip" {
    description = "Web GW IP address"
    type = string
}

variable "dependency" {
    description = "Dummy variable for dependency"
    type = string
}

variable "security_group_ids" {
    description = "List of security group Ids"
    type = list(string)
}

variable "ssm_instance_profile_name" {
    description = "Instance profile name for SSM"
    type = string
}

variable "ami" {
    description = "Base AMI"
    type = string
}

variable "eip_id" {
    description = "Elastic IP id for this server"
    type = string
}

variable "eip" {
    description = "Elastic IP for this server"
    type = string
}

variable "prd_crm_ip" {
    description = "Prod CRM IP"
    type = string
}

variable "prd_hrm_ip" {
    description = "Prod HRM IP"
    type = string
}

variable "prd_portal_ip" {
    description = "Prod Portal IP"
    type = string
}

variable "webstore_ip" {
    description = "Webstore IP"
    type = string
}

variable "kind_ip" {
    description = "Kind Host IP"
    type = string
}

variable "siem_ip" {
    description = "IP address of the SIEM"
    type = string
}

variable "assetmgr_ip" {
    description = "IP address of the Asset Manager"
    type = string
}

variable "xs_agent_debian_pkg_url" {
    description = "Debian package URL for the Host Agent"
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