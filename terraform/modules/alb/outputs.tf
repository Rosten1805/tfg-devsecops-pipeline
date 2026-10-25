output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "Short ARN form CloudWatch metrics use for the LoadBalancer dimension."
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "Short ARN form CloudWatch metrics use for the TargetGroup dimension."
  value       = aws_lb_target_group.app.arn_suffix
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs_tasks.id
}
