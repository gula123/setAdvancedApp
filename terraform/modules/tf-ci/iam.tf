# IAM Role for CI CodeBuild Project
resource "aws_iam_role" "ci_codebuild_role" {
  name = "ci-codebuild-role-${var.environment}"

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
    Name        = "ci-codebuild-role-${var.environment}"
    Environment = var.environment
  }
}

# IAM Policy for CI CodeBuild
resource "aws_iam_role_policy" "ci_codebuild_policy" {
  name = "ci-codebuild-policy-${var.environment}"
  role = aws_iam_role.ci_codebuild_role.id

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
        Resource = "${aws_s3_bucket.ci_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.ci_artifacts.arn
      }
    ]
  })
}

# IAM Role for CodePipeline (CI Only)
resource "aws_iam_role" "ci_codepipeline_role" {
  name = "ci-codepipeline-role-${var.environment}"

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
    Name        = "ci-codepipeline-role-${var.environment}"
    Environment = var.environment
  }
}

# IAM Policy for CI CodePipeline
resource "aws_iam_role_policy" "ci_codepipeline_policy" {
  name = "ci-codepipeline-policy-${var.environment}"
  role = aws_iam_role.ci_codepipeline_role.id

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
          aws_s3_bucket.ci_artifacts.arn,
          "${aws_s3_bucket.ci_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.ci_build.arn
      }
    ]
  })
}