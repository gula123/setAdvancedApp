# ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster-${var.environment}"

  tags = {
    Name        = "app-cluster-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/app-${var.environment}"
  retention_in_days = 7

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
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true
  }

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "app-container"
    container_port   = var.application_port
  }

  depends_on = [aws_lb_listener.app_listener]

  tags = {
    Name        = "app-service-${var.environment}"
    Environment = var.environment
  }
}