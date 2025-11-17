# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "app-cluster-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/app-${var.environment}"
  retention_in_days = 365  # Retain logs for 1 year (Checkov requirement)
  kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn

  tags = {
    Name        = "ecs-log-group-${var.environment}"
    Environment = var.environment
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name               = "ecs-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name        = "ecs-execution-role-${var.environment}"
    Environment = var.environment
  }
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name               = "ecs-task-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = {
    Name        = "ecs-task-role-${var.environment}"
    Environment = var.environment
  }
}

# Attach policies to execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_execution_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_cloudwatch" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = data.aws_iam_policy.cloudwatch_logs_full_access.arn
}

# Attach policies to task role
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.s3_full_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_dynamodb" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.dynamodb_full_access.arn
}

# Security Group for ECS Service
resource "aws_security_group" "ecs_service_sg" {
  name_prefix = "ecs-service-${var.environment}"
  description = "Security group for ECS service tasks"
  vpc_id      = var.vpc_id

  # Allow inbound from ALB on application port
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  # Allow HTTPS outbound for external APIs and services
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "HTTPS outbound for external APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP outbound for AWS services
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "HTTP outbound for AWS services"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to DynamoDB port (HTTPS)
  egress {
    description = "DynamoDB access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name        = "ecs-service-sg-${var.environment}"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task-${var.environment}"
  network_mode             = "awsvpc"
  memory                   = 3072
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "app-container"
    image = var.image_uri

    essential = true

    portMappings = [{
      containerPort = var.application_port
      hostPort      = var.application_port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = var.region_name
        "awslogs-stream-prefix" = "ecs"
      }
    }

    environment = [
      {
        name  = "S3_BUCKET_NAME"
        value = var.s3_bucket_name
      },
      {
        name  = "DYNAMODB_TABLE_NAME"
        value = var.dynamodb_table_name
      },
      {
        name  = "AWS_DEFAULT_REGION"
        value = var.region_name
      },
      {
        name  = "SPRING_PROFILES_ACTIVE"
        value = var.environment
      }
    ]
  }])

  tags = {
    Name        = "app-task-${var.environment}"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "app-service-${var.environment}"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"

  deployment_controller {
    type = var.enable_blue_green_deployment ? "CODE_DEPLOY" : "ECS"
  }

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "app-container"
    container_port   = var.application_port
  }

  depends_on = [aws_lb_listener.app_listener_http]

  tags = {
    Name        = "app-service-${var.environment}"
    Environment = var.environment
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}