resource "aws_flow_log" "vpc_flow_log" {
#   iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination      = aws_s3_bucket.vpc_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.selected.id

  tags = {
    Name = "${var.name_prefix}-vpc-flow-logs"
  }
}
