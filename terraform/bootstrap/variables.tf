variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state."
  type        = string
  default     = "tft-devsecops-tfstate-921049725767"
}
