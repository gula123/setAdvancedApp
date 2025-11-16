# CodeBuild service role for CI Pipeline
resource "aws_iam_role" "codebuild_ci_role" {
  name = "codebuild-ci-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "codebuild-ci-role-${var.environment}"
    Environment = var.environment
  }
}

# CodeBuild service role for Deployment Pipeline
resource "aws_iam_role" "codebuild_deploy_role" {
  name = "codebuild-deploy-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "codebuild-deploy-role-${var.environment}"
    Environment = var.environment
  }
}

# CodePipeline service role
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "codepipeline-role-${var.environment}"
    Environment = var.environment
  }
}

# Policy for CI CodeBuild role
resource "aws_iam_role_policy" "codebuild_ci_policy" {
  name = "codebuild-ci-policy-${var.environment}"
  role = aws_iam_role.codebuild_ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.codepipeline_artifacts.arn
      }
    ]
  })
}

# Policy for Deployment CodeBuild role
resource "aws_iam_role_policy" "codebuild_deploy_policy" {
  name = "codebuild-deploy-policy-${var.environment}"
  role = aws_iam_role.codebuild_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.codepipeline_artifacts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "s3.${var.region}.amazonaws.com"
            ]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda_function_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CodePipeline role
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline-policy-${var.environment}"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = [
          aws_codebuild_project.ci_build.arn,
          aws_codebuild_project.deploy_build.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# CodeBuild service role for PR Validation
resource "aws_iam_role" "codebuild_pr_validation_role" {
  count = var.enable_pr_validation ? 1 : 0
  name  = "codebuild-pr-validation-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "codebuild-pr-validation-role-${var.environment}"
    Environment = var.environment
    Purpose     = "PR Validation"
  }
}

# Policy for PR Validation CodeBuild role
resource "aws_iam_role_policy" "codebuild_pr_validation_policy" {
  count = var.enable_pr_validation ? 1 : 0
  name  = "codebuild-pr-validation-policy-${var.environment}"
  role  = aws_iam_role.codebuild_pr_validation_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge service role for PR validation
resource "aws_iam_role" "eventbridge_pr_validation_role" {
  count = var.enable_pr_validation ? 1 : 0
  name  = "eventbridge-pr-validation-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "eventbridge-pr-validation-role-${var.environment}"
    Environment = var.environment
  }
}

# Policy for EventBridge to trigger CodeBuild
resource "aws_iam_role_policy" "eventbridge_pr_validation_policy" {
  count = var.enable_pr_validation ? 1 : 0
  name  = "eventbridge-pr-validation-policy-${var.environment}"
  role  = aws_iam_role.eventbridge_pr_validation_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.pr_validation[0].arn
      }
    ]
  })
}