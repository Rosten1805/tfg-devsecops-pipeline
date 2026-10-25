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

module "ec2" {
  source = "./modules/ec2"

  project_name          = var.project_name
  environment           = var.environment
  public_subnet_id      = module.networking.public_subnet_ids[0]
  app_security_group_id = module.alb.app_security_group_id
  ecr_repository_url    = module.ecr.repository_url
  image_tag             = var.image_tag
  container_port        = var.container_port

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

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.alb.target_group_arn
  target_id        = module.ec2.instance_id
  port             = var.container_port
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email

  instance_id             = module.ec2.instance_id
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}
