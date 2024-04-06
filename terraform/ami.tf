data "aws_ami" "ubuntu_22_04" {
    most_recent = true
    owners = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu*22.04*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

data "aws_ami" "win2019" {
    most_recent = true
    owners = ["801119661308"] # Microsoft

    filter {
        name   = "name"
        values = ["Windows_Server-2019-English-Full-Base*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

data "aws_ami" "win2016" {
    most_recent = true
    owners = ["801119661308"] # Microsoft

    filter {
        name   = "name"
        values = ["Windows_Server-2016-English-Full-Base*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}