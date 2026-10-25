output "app_url" {
  description = "Public URL of the deployed app."
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "instance_public_ip" {
  value = module.ec2.public_ip
}
