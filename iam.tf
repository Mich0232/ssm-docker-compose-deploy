resource "aws_sns_topic" "main" {
  name = local.name

  tags = merge(local.common_tags, {
    Name      = "Deployment Notifications"
  })
}

resource "aws_sns_topic_policy" "main" {
  arn = aws_sns_topic.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.main.arn
      }
    ]
  })
}

resource "aws_iam_role" "main" {
  name = "${local.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "main" {
  name = "${local.name}-role-policy"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.main.arn
      }
    ]
  })
}

data "aws_iam_policy" "ssm_automation_policy" {
  name = var.default_iam_policy_name
}

resource "aws_iam_role_policy_attachment" "ssm_automation_policy_attachment" {
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.ssm_automation_policy.arn
}