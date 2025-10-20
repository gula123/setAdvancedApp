# Application Load Balancer
resource "aws_lb" "app_load_balancer" {
  name               = "app-lb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "app-lb-${var.environment}"
    Environment = var.environment
  }
}

# Load Balancer Target Group
resource "aws_lb_target_group" "app_target_group" {
  name     = "app-tg-${var.environment}"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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
    Name        = "app-tg-${var.environment}"
    Environment = var.environment
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }

  tags = {
    Name        = "app-listener-${var.environment}"
    Environment = var.environment
  }
}