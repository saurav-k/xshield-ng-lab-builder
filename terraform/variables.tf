variable "lab_name" {
    description = "The name of this lab.  Will be combined with loc_name as a prefix for all AWS resources and hostnames"
    type = string
    default = "acme"
}

variable "loc_name" {
    description = "The location of the lab.  See also lab_name."
    type = string
    default = "usw"
}

variable "owner_initials" {
    description = "Your nickname or initials - to identify your AWS resources"
    type = string
    nullable = false
    validation {
        condition = length(var.owner_initials) >=2
        error_message = "At least 2 characters,please!"
    }
}

variable "windows_instance_type" {
    description = "EC2 instance type for Windows VMs"
    type = string
    default = "t3.medium"
}

variable "linux_instance_type" {
    description = "EC2 instance type for Linux VMs"
    type = string
    default = "t3.small"
}