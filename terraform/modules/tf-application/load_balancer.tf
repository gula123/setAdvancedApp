# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "alb-logs-${var.environment}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "alb-logs-${var.environment}"
    Environment = var.environment
  }
}

# S3 bucket for ALB logs access logging
resource "aws_s3_bucket" "alb_logs_access_logs" {
  bucket        = "alb-logs-access-${var.environment}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name        = "alb-logs-access-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_access_logs_pab" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for ALB logs access logs bucket
resource "aws_s3_bucket_versioning" "alb_logs_access_logs_versioning" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for ALB logs access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_access_logs_encryption" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudwatch_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Enable logging for ALB logs access logs bucket
resource "aws_s3_bucket_logging" "alb_logs_access_logs_logging" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  target_bucket = aws_s3_bucket.audit_logs.id
  target_prefix = "alb-access-logs/"
}

# Lifecycle configuration for ALB logs access logs bucket
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_access_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_logs_access_logs.id

  rule {
    id     = "delete_old_access_logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs_encryption" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudwatch_logs_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 bucket versioning for ALB logs
resource "aws_s3_bucket_versioning" "alb_logs_versioning" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable access logging for ALB logs bucket
resource "aws_s3_bucket_logging" "alb_logs_logging" {
  bucket = aws_s3_bucket.alb_logs.id

  target_bucket = aws_s3_bucket.alb_logs_access_logs.id
  target_prefix = "alb-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Data source for ALB service account
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
      }
    ]
  })
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb_security_group" {
  name_prefix = "alb-sg-${var.environment}"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  # Allow HTTP traffic from internet (for redirect to HTTPS)
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTP from internet for redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from internet
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Restrict egress to only necessary ports for ECS communication
  egress {
    description = "HTTP to ECS targets"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow HTTPS outbound for health checks and external APIs
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg-${var.environment}"
    Environment = var.environment
  }
}

# Application Load Balancer
#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "app_load_balancer" {
  name               = "app-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  drop_invalid_header_fields = true

  # Disable access logging initially to avoid permission race condition
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = false
  }

  tags = {
    Name        = "app-lb-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_s3_bucket_policy.alb_logs_policy]
}

# Load Balancer Target Group
resource "aws_lb_target_group" "app_target_group" {
  name        = "app-tg-${var.environment}"
  port        = var.application_port
  protocol    = "HTTP"  # Keep HTTP for internal communication with ECS
  vpc_id      = var.vpc_id
  target_type = "ip"    # Required for ECS Fargate

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"  # Health check remains HTTP
  }

  tags = {
    Name        = "app-tg-${var.environment}"
    Environment = var.environment
  }
}

# Second target group for blue-green deployment (only created when enabled)
resource "aws_lb_target_group" "app_target_group_green" {
  count       = var.enable_blue_green_deployment ? 1 : 0
  name        = "app-tg-green-${var.environment}"
  port        = var.application_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name        = "app-tg-green-${var.environment}"
    Environment = var.environment
  }
}

# HTTP Listener - Redirect to HTTPS when HTTPS is enabled
resource "aws_lb_listener" "app_listener_http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.enable_https ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.enable_https ? [] : [1]
      content {
        target_group {
          arn = aws_lb_target_group.app_target_group.arn
        }
      }
    }
  }

  tags = {
    Name        = "app-listener-http-${var.environment}"
    Environment = var.environment
  }
}

# HTTPS Listener - Only created when HTTPS is enabled
resource "aws_lb_listener" "app_listener_https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = local.certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.app_target_group.arn
      }
    }
  }

  tags = {
    Name        = "app-listener-https-${var.environment}"
    Environment = var.environment
  }
}