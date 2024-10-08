resource "aws_s3_bucket" "vpc_logs" {
  bucket = "${var.bucket_name_prefix}-vpc-logs"

  tags = {
    Name = "${var.bucket_name_prefix}-vpc-logs"
    Owner = var.owner_name
  }
}

# resource "aws_s3_bucket_policy" "vpc_logs_policy" {
#   bucket = aws_s3_bucket.vpc_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "vpc-flow-logs.amazonaws.com"
#         }
#         Action = "s3:PutObject"
#         Resource = "${aws_s3_bucket.vpc_logs.arn}/*"
#         Condition = {
#         #   StringEquals = {
#         #     "aws:SourceAccount" = var.aws_account_id
#         #   }
#           ArnLike = {
#             "aws:SourceArn" = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/${data.aws_vpc.selected.id}"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket_policy" "vpc_logs_policy" {
#   bucket = aws_s3_bucket.vpc_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "vpc-flow-logs.amazonaws.com"
#         }
#         Action = "s3:PutObject"
#         Resource = "${aws_s3_bucket.vpc_logs.arn}/*"
#         Condition = {
#           StringEquals = {
#             "aws:SourceAccount" = data.aws_caller_identity.current.account_id
#           }
#           ArnLike = {
#             "aws:SourceArn" = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/${data.aws_vpc.selected.id}"
#           }
#         }
#       }
#     ]
#   })
# }

resource "aws_s3_bucket_policy" "vpc_logs_policy" {
  bucket = aws_s3_bucket.vpc_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "s3:*"
        Resource = "${aws_s3_bucket.vpc_logs.arn}/*"
      }
    ]
  })
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log_role" {
  name               = "flow_log_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "flow_log_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "${aws_s3_bucket.vpc_logs.arn}",
      "${aws_s3_bucket.vpc_logs.arn}/*"
    ]
  }
}



resource "aws_iam_role_policy" "flow_log_role_policy" {
  name   = "flow_log_role_policy"
  role   = aws_iam_role.flow_log_role.id
  policy = data.aws_iam_policy_document.flow_log_role_policy.json
}