variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "max_image_count" {
  type    = number
  default = 10
}

variable "untagged_image_expiry_days" {
  type    = number
  default = 7
}
