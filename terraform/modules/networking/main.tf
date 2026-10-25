locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Resolved from the provider's region at apply time instead of hardcoding AZ
# names — more portable than pinning e.g. "us-east-1a" in a variable default.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# Public subnets only — no NAT Gateway, no private subnets. The compute
# (a single EC2 instance, see the ec2 module) lives here directly instead of
# behind NAT, which is a deliberate simplification forced by this account's
# IAM restrictions: it can't create the IAM roles ECS Fargate requires, so
# there is no private-subnet workload left to justify NAT's cost/complexity.
# Documented in the TFT write-up, not an oversight.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Lock down the VPC's default security group to deny-all, per AWS/CIS
# guidance — resources should use purpose-built security groups instead.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-default-sg-locked-down"
  }
}

# VPC Flow Logs intentionally omitted: aws_flow_log needs an IAM role
# (logs:CreateLogStream/PutLogEvents), and this account's PowerUserAccess
# role cannot call iam:CreateRole — confirmed empirically (AccessDenied) when
# this was attempted, not just inferred from reading the policy. See the TFT
# write-up for the full account-restriction findings.
