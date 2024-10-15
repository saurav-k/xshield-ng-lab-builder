# resource "aws_instance" "db" {
#   ami               = var.ami
#   instance_type     = "t3.small"
#   key_name          = var.key_name
#   subnet_id         = var.subnet_id
#   vpc_security_group_ids = [var.internal_sg_id]
#   private_ip        = var.db_ip
#   iam_instance_profile = var.ssm_instance_profile_name

#   tags = {
#     Name = "${var.name_prefix}-db"
#     Owner = var.owner_name
#     Dependency = var.dependency
#   }

#   user_data = base64encode(join("\n", [
#       templatefile("${path.module}/user_data_templates/db_user_data.sh",
#         {   hostname = "${var.hostname_prefix}db",
#             password = var.password,            
#             legacy_db_ip_prefix = var.legacy_db_ip_prefix,
#             legacy_db_count = var.legacy_db_count
#         }),
#       templatefile("${path.root}/common_user_data_templates/debian_agents.sh",
#         {  
#             assetmgr_ip = var.assetmgr_ip,
#             siem_ip = var.siem_ip,
#             xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url,
#             xs_domain = var.xs_domain,
#             xs_deployment_key = var.xs_deployment_key
#         })
#       ]
#     ))
# }

locals {
  sanitized_name_prefix = replace(replace(replace(var.name_prefix, ".", "-"), "@", "-"), ",", "-")
}

# resource "aws_security_group_rule" "allow_service_ingress" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   security_group_id        = var.internal_sg_id
#   source_security_group_id = var.internal_sg_id
# }

# resource "aws_security_group_rule" "allow_internet_ingress" {
#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   cidr_blocks             = ["0.0.0.0/0"]
#   security_group_id        = var.internal_sg_id
# }

# resource "aws_security_group_rule" "allow_all_egress" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = -1
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = var.internal_sg_id
# }

resource "aws_db_subnet_group" "db-subnet" {
  name       = "${local.sanitized_name_prefix}-db-subnet"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${local.sanitized_name_prefix}-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  engine_version          = "8.0.mysql_aurora.3.07.1" # Example version, choose your preferred one
  master_username         = var.rds_db_username
  master_password         = var.rds_db_password
  database_name           = var.rds_db_name
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  storage_encrypted       = true

  vpc_security_group_ids = [var.internal_sg_id]
  db_subnet_group_name   = aws_db_subnet_group.db-subnet.name

    # Add the scaling configuration for Serverless v2
  # scaling_configuration {
  #   min_capacity = 1  # The minimum Aurora capacity unit (ACU)
  #   max_capacity = 16   # The maximum Aurora capacity unit (ACU)
  #   auto_pause   = false  # Auto-pause can be enabled/disabled
  # }
  serverlessv2_scaling_configuration {
    max_capacity = 10
    min_capacity = 2
  }

    tags = {
    Name = "${var.name_prefix}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = 1
  
  identifier         = "${local.sanitized_name_prefix}-aurora-instance-${count.index+1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class       = "db.serverless" # Modify instance type as required
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
  publicly_accessible = false

  db_subnet_group_name   = aws_db_subnet_group.db-subnet.name

  tags = {
    Name = "${var.name_prefix}-aurora-instance-${count.index+1}"
    Owner = var.owner_name
    Dependency = var.dependency
  }
}

output "db_host" {
  value = aws_rds_cluster.aurora.endpoint
}

resource "aws_instance" "app" {
  depends_on = [ aws_rds_cluster.aurora, aws_rds_cluster_instance.aurora_instances ]
  count             = var.app_server_count
  ami               = var.ami
  instance_type     = "t3.micro"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = "${var.app_ip_prefix}${count.index+1}"
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-app-${count.index+1}"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/db_user_data_rds.sh",
        {   
            hostname       = "${var.hostname_prefix}app${count.index+1}",
            db_endpoint    = aws_rds_cluster.aurora.endpoint,  # Aurora Cluster endpoint
            db_port        = aws_rds_cluster.aurora.port,      # Aurora port
            db_name        = var.rds_db_name,
            db_username    = var.rds_db_username,
            db_password    = var.rds_db_password,
            crm_password   = var.crm_password                 
            # Admin password for CRM
        }),
      templatefile("${path.module}/user_data_templates/app_user_data.sh",
        {   hostname = "${var.hostname_prefix}app${count.index+1}",
            crm_password = var.crm_password,    
            db_endpoint = aws_rds_cluster.aurora.endpoint,  # Aurora Cluster endpoint
            web_gateway_ip = var.web_gateway_ip
        }),
      templatefile("${path.root}/common_user_data_templates/debian_agents.sh",
        {  
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip,
            xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url,
            xs_domain = var.xs_domain,
            xs_deployment_key = var.xs_deployment_key
        })
      ]
    ))
}

resource "aws_instance" "web" {
  ami               = var.ami
  instance_type     = "t3.micro"
  key_name          = var.key_name
  subnet_id         = var.subnet_id
  vpc_security_group_ids = [var.internal_sg_id]
  private_ip        = var.web_ip
  iam_instance_profile = var.ssm_instance_profile_name

  tags = {
    Name = "${var.name_prefix}-web"
    Owner = var.owner_name
    Dependency = var.dependency
  }

  user_data = base64encode(join("\n", [
      templatefile("${path.module}/user_data_templates/web_user_data.sh",
        {   hostname = "${var.hostname_prefix}web",
            app_ip_prefix = var.app_ip_prefix,
        }),
      templatefile("${path.root}/common_user_data_templates/debian_agents.sh",
        {  
            assetmgr_ip = var.assetmgr_ip,
            siem_ip = var.siem_ip,
            xs_agent_debian_pkg_url = var.xs_agent_debian_pkg_url,
            xs_domain = var.xs_domain,
            xs_deployment_key = var.xs_deployment_key
        })
      ]
    ))
}