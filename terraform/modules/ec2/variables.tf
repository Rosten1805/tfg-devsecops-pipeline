variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ecr_repository_url" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "container_port" {
  type    = number
  default = 3000
}

# --- App runtime configuration -----------------------------------------
# No IAM role is attached to this instance (see networking/alb module
# comments and the TFT write-up for why), so none of this can be injected via
# SSM/Secrets Manager at boot the way it would be on ECS — it's baked
# directly into the instance's user_data instead. That's a real, documented
# security trade-off, not an oversight. Supply real values via a gitignored
# terraform.tfvars or TF_VAR_* env vars, never commit them.

variable "tmdb_api_url" {
  type    = string
  default = "https://api.themoviedb.org"
}

variable "nextauth_url" {
  type = string
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
  type = string
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
  type    = string
  default = ""
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
