variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "project_name" {
  type    = string
  default = "tft-devsecops"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "ecr_repository_name" {
  type    = string
  default = "disney-plus-clone"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "desired_count" {
  type    = number
  default = 1
}

# No default — ECR uses IMMUTABLE tags, so this must be passed explicitly on
# every apply (e.g. the git SHA CI tagged the image with).
variable "image_tag" {
  type = string
}

variable "alert_email" {
  description = "Where CloudWatch alarm notifications (via SNS) are sent."
  type        = string
}

# --- App runtime secrets/config — see terraform/modules/ecs/variables.tf for
# which of these are written to SSM Parameter Store vs. passed as plain env.
# Supply real values via terraform.tfvars (gitignored) or TF_VAR_* env vars,
# never commit them.

variable "nextauth_url" {
  type = string
}

variable "tmdb_api_key" {
  type      = string
  sensitive = true
}

variable "tmdb_api_url" {
  type    = string
  default = "https://api.themoviedb.org/3"
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
