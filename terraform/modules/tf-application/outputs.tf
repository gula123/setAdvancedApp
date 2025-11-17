output "load_balancer_dns_name" {
  value       = aws_lb.app_load_balancer.dns_name
  description = "DNS name of the load balancer"
}

output "load_balancer_zone_id" {
  value       = aws_lb.app_load_balancer.zone_id
  description = "Zone ID of the load balancer"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.app_cluster.name
  description = "Name of the ECS cluster"
}

output "ecs_service_name" {
  value       = aws_ecs_service.app_service.name
  description = "Name of the ECS service"
}

output "lambda_function_name" {
  value       = aws_lambda_function.image_processing_lambda.function_name
  description = "Name of the Lambda function"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.image_processing_lambda.arn
  description = "ARN of the Lambda function"
}

output "alb_listener_arn" {
  value       = aws_lb_listener.app_listener_http.arn
  description = "ARN of the ALB listener"
}

output "target_group_name" {
  value       = aws_lb_target_group.app_target_group.name
  description = "Name of the ALB target group"
}

output "target_group_green_name" {
  value       = var.enable_blue_green_deployment ? aws_lb_target_group.app_target_group_green[0].name : null
  description = "Name of the green ALB target group for blue-green deployment"
}