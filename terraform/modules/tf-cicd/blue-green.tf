# Blue-Green deployment configuration using AWS CodeDeploy
resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.project_name}-app-${var.environment}"

  tags = {
    Name        = "${var.project_name}-app-${var.environment}"
    Environment = var.environment
  }
}

# CodeDeploy service role
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "codedeploy-role-${var.environment}"
    Environment = var.environment
  }
}

# Attach AWS managed policy for CodeDeploy ECS
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# CodeDeploy deployment group for Blue-Green deployment
resource "aws_codedeploy_deployment_group" "app_deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.project_name}-deployment-group-${var.environment}"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = aws_codedeploy_deployment_config.ecs_blue_green.id

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                         = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arn]
      }

      target_group {
        name = var.target_group_name
      }

      target_group {
        name = var.target_group_green_name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-deployment-group-${var.environment}"
    Environment = var.environment
  }
}

# CodeDeploy deployment configuration for ECS Blue-Green
resource "aws_codedeploy_deployment_config" "ecs_blue_green" {
  deployment_config_name = "${var.project_name}-ECSBlueGreen-${var.environment}"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "AllAtOnce"
  }
}
