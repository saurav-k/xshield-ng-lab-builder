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

variable "kind_ip" {
    description = "Host IP address"
    type = string
}

variable "web_gw_ip" {
    description = "Web Gateway IP address"
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

variable "xs_container_agent_version" {
    description = "Xshield Container Agent version"
    type = string
}

variable "xs_container_registry_uri" {
    description = "Xshield Container Registry URI"
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