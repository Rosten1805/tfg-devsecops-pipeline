variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ecr_repository_url" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "image_tag" {
  description = "No default: ECR uses IMMUTABLE tags, so this must be passed explicitly on every apply (e.g. the git SHA of the image CI pushed)."
  type        = string
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "alb_security_group_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "alb_target_group_arn" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

# --- App runtime configuration -----------------------------------------
# Non-secret values go in `environment`; secret values are written to SSM
# Parameter Store (SecureString, AWS-managed key) by this module and read by
# the task via the `secrets` block — never as plaintext in the task
# definition. Supply real values via a gitignored terraform.tfvars or
# TF_VAR_* environment variables, never hardcoded here.

variable "tmdb_api_url" {
  type    = string
  default = "https://api.themoviedb.org/3"
}

variable "nextauth_url" {
  description = "Public URL of the deployed app (the ALB DNS name, or a custom domain)."
  type        = string
}

variable "tmdb_api_key" {
  type      = string
  sensitive = true
}

variable "nextauth_secret" {
  type      = string
  sensitive = true
}

variable "google_id" {
  description = "Google OAuth client ID — not secret (it's visible in the browser's OAuth redirect), unlike google_secret."
  type        = string
}

variable "google_secret" {
  type      = string
  sensitive = true
}

variable "database_url" {
  type      = string
  sensitive = true
}

variable "smtp_host" {
  description = "Optional — without it the app falls back to a disposable test inbox (see app README)."
  type        = string
  default     = ""
}

variable "smtp_port" {
  type    = string
  default = ""
}

variable "smtp_user" {
  type      = string
  sensitive = true
  default   = ""
}

variable "smtp_pass" {
  type      = string
  sensitive = true
  default   = ""
}

variable "smtp_from" {
  type    = string
  default = ""
}
