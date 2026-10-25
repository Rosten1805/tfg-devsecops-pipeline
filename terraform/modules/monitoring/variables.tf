variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  description = "Email address subscribed to the SNS topic that receives alarm notifications. AWS sends a confirmation link to this address the first time the topic is applied — it must be clicked before notifications flow."
  type        = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}
