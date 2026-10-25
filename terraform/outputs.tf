output "app_url" {
  description = "Public URL of the deployed app."
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
