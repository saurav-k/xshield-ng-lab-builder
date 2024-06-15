variable "key_name" {
    description = "Key name for instance creation"
    type = string
}

variable "password" {
    description = "Password for database and default admin accounts"
    type = string
    sensitive = true
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

variable "db_ip" {
    description = "Database IP address"
    type = string
}

variable "app_ip" {
    description = "App server IP address"
    type = string
}

variable "web_ip" {
    description = "Web server IP address"
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