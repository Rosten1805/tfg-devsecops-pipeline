locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ALB access logging to S3 intentionally omitted for this TFT — it needs a
# region-specific ELB log-delivery account policy and adds another bucket to
# manage; CloudWatch + the app's own request logs cover troubleshooting needs
# at this scale. Documented as a known simplification.

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "ALB security group - allows inbound HTTP from the internet, forwards to the app instance only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP from anywhere - this is a public-facing demo ALB"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.app.id
  description                  = "Allow outbound from ALB to the app instance only, on the app port"
}

# Security group for the app's compute (a single EC2 instance — see the ec2
# module). No IAM instance profile is attached to that instance (this
# account's PowerUserAccess role can't create one — see TFT write-up), so
# network isolation via this security group is the primary control: only the
# ALB may reach the app port, nothing else is open in by default.
resource "aws_security_group" "app" {
  name_prefix = "${local.name_prefix}-app-"
  description = "App instance security group - accepts traffic only from the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "Allow inbound from the ALB only, on the app port"
}

resource "aws_vpc_security_group_egress_rule" "app_https_egress" {
  security_group_id = aws_security_group.app.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTPS egress for ECR image pull, TMDB API, other external APIs - instance has a public IP (no NAT)"
}

resource "aws_vpc_security_group_egress_rule" "app_http_egress" {
  security_group_id = aws_security_group.app.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "HTTP egress - needed for apt/dnf package installs during instance bootstrap"
}

resource "aws_vpc_security_group_egress_rule" "app_postgres_egress" {
  security_group_id = aws_security_group.app.id
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Postgres egress to the managed Neon database (DATABASE_URL) - Neon has no fixed IP range to narrow this to"
}

resource "aws_vpc_security_group_egress_rule" "app_smtp_egress" {
  security_group_id = aws_security_group.app.id
  from_port         = 587
  to_port           = 587
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "SMTP submission egress - needed both for a real SMTP relay (SMTP_* vars) and for the Ethereal test-inbox fallback (library/mailer.ts) used when no SMTP_HOST is configured"
}

resource "aws_lb" "main" {
  name                       = "${local.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  # name_prefix (unique random suffix), not a fixed name: with
  # create_before_destroy, a fixed name collides with the old target group
  # that's still being destroyed every time this must be replaced.
  name_prefix = "tg-"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance" # EC2 instance target, not Fargate ENI ("ip")

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true # avoid "target group in use by a listener" when it must be replaced
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
