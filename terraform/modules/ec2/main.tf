locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# AWS's own always-current alias for the latest Amazon Linux 2023 AMI —
# simpler and more reliable than filtering aws_ami by name/owner.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Short-lived (~12h) ECR authorization token, fetched using the *caller's*
# (the operator applying this config) AWS credentials — not a role on the
# instance, which has none. This is what lets the instance pull the private
# ECR image without any IAM role of its own.
data "aws_ecr_authorization_token" "token" {}

locals {
  ecr_registry = regex("^https://(.+)$", data.aws_ecr_authorization_token.token.proxy_endpoint)[0]

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    ecr_password   = data.aws_ecr_authorization_token.token.password
    ecr_registry   = local.ecr_registry
    image          = "${var.ecr_repository_url}:${var.image_tag}"
    container_port = var.container_port

    google_id       = var.google_id
    tmdb_api_url    = var.tmdb_api_url
    nextauth_url    = var.nextauth_url
    tmdb_api_key    = var.tmdb_api_key
    nextauth_secret = var.nextauth_secret
    google_secret   = var.google_secret
    database_url    = var.database_url
    smtp_host       = var.smtp_host
    smtp_port       = var.smtp_port
    smtp_user       = var.smtp_user
    smtp_pass       = var.smtp_pass
    smtp_from       = var.smtp_from
  })
}

resource "aws_instance" "app" {
  ami           = nonsensitive(data.aws_ssm_parameter.al2023_ami.value)
  instance_type = var.instance_type

  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.app_security_group_id]
  associate_public_ip_address = true

  # No iam_instance_profile on purpose — this account's PowerUserAccess role
  # cannot create IAM roles (confirmed empirically), so there is none to
  # attach. See the networking/alb module comments and the TFT write-up.

  user_data                   = local.user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${local.name_prefix}-app"
  }
}
