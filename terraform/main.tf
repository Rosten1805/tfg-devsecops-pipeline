module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
}

module "ecr" {
  source = "./modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = var.ecr_repository_name
}

module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = var.container_port
}

module "ecs" {
  source = "./modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  image_tag          = var.image_tag
  container_port     = var.container_port
  desired_count      = var.desired_count

  alb_security_group_id = module.alb.alb_security_group_id
  ecs_security_group_id = module.alb.ecs_security_group_id
  alb_target_group_arn  = module.alb.target_group_arn

  nextauth_url    = var.nextauth_url
  tmdb_api_key    = var.tmdb_api_key
  tmdb_api_url    = var.tmdb_api_url
  nextauth_secret = var.nextauth_secret
  google_id       = var.google_id
  google_secret   = var.google_secret
  database_url    = var.database_url
  smtp_host       = var.smtp_host
  smtp_port       = var.smtp_port
  smtp_user       = var.smtp_user
  smtp_pass       = var.smtp_pass
  smtp_from       = var.smtp_from
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email

  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}
