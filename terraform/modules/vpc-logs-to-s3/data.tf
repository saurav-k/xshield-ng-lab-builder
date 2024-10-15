data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["${var.name_prefix}-vpc"]
  }

  filter {
    name   = "tag:Owner"
    values = [var.owner_name]
  }
}


data "aws_caller_identity" "current" {}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}