locals {
  name_prefix = "${var.project_name}-${var.environment}"

  secret_values = {
    NEXTAUTH_SECRET = var.nextauth_secret
    GOOGLE_SECRET   = var.google_secret
    DATABASE_URL    = var.database_url
    TMDB_API_KEY    = var.tmdb_api_key
    SMTP_USER       = var.smtp_user
    SMTP_PASS       = var.smtp_pass
  }

  # SMTP is optional (see app README) — only create/reference a parameter and
  # inject it into the container for values that were actually supplied.
  #
  # `for_each` can't key off a value derived from a sensitive input (Terraform
  # refuses it: the resource-instance keys could expose the secret). nextauth_
  # secret/google_secret/database_url/tmdb_api_key have no default — they're
  # always present, so no presence check is needed for them. For the two
  # optional ones, nonsensitive() is safe here because it only downgrades the
  # *presence boolean* ("was something supplied?"), never the secret value
  # itself, which is looked up separately (and stays sensitive) below.
  smtp_user_present = nonsensitive(var.smtp_user != "")
  smtp_pass_present = nonsensitive(var.smtp_pass != "")

  secret_keys = concat(
    ["NEXTAUTH_SECRET", "GOOGLE_SECRET", "DATABASE_URL", "TMDB_API_KEY"],
    local.smtp_user_present ? ["SMTP_USER"] : [],
    local.smtp_pass_present ? ["SMTP_PASS"] : [],
  )

  plain_env = merge(
    {
      NODE_ENV     = "production"
      GOOGLE_ID    = var.google_id
      TMDB_API_URL = var.tmdb_api_url
      NEXTAUTH_URL = var.nextauth_url
    },
    var.smtp_host != "" ? { SMTP_HOST = var.smtp_host } : {},
    var.smtp_port != "" ? { SMTP_PORT = var.smtp_port } : {},
    var.smtp_from != "" ? { SMTP_FROM = var.smtp_from } : {},
  )
}

data "aws_region" "current" {}

# --- Secrets: SSM Parameter Store (SecureString, AWS-managed key) ----------
# AWS-managed key ("alias/aws/ssm") rather than a dedicated customer-managed
# KMS key — same deliberate simplification applied elsewhere in this project.

resource "aws_ssm_parameter" "secrets" {
  for_each = toset(local.secret_keys)

  name  = "/${local.name_prefix}/${each.key}"
  type  = "SecureString"
  value = local.secret_values[each.key]

  tags = {
    Name = "${local.name_prefix}-${each.key}"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-ecs-logs"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# --- IAM: task execution role (pulls the image, writes logs, reads secrets) -

resource "aws_iam_role" "task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy" "task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-policy"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "ECRAuth"
          Effect   = "Allow"
          Action   = ["ecr:GetAuthorizationToken"]
          Resource = "*"
        },
        {
          Sid    = "ECRPull"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ]
          Resource = var.ecr_repository_arn
        },
        {
          Sid      = "CloudWatchLogsWrite"
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "${aws_cloudwatch_log_group.app.arn}:*"
        }
      ],
      length(aws_ssm_parameter.secrets) > 0 ? [
        {
          Sid      = "ReadAppSecrets"
          Effect   = "Allow"
          Action   = ["ssm:GetParameters"]
          Resource = [for p in aws_ssm_parameter.secrets : p.arn]
        }
      ] : []
    )
  })
}

# Task role: permissions the *application* itself would need at runtime to
# call AWS APIs. Left with no inline policy — this app talks to Neon Postgres
# and TMDB, both external to AWS, not to any AWS service at request time.
resource "aws_iam_role" "task_role" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [
        { containerPort = var.container_port, protocol = "tcp" }
      ]

      environment = [
        for k, v in local.plain_env : { name = k, value = v }
      ]

      secrets = [
        for k, p in aws_ssm_parameter.secrets : { name = k, valueFrom = p.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "node -e \"require('http').get('http://127.0.0.1:${var.container_port}/api/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-app-task"
  }
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  tags = {
    Name = "${local.name_prefix}-service"
  }
}
