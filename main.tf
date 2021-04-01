terraform {
  backend "s3" {
    bucket = "terraform-maslick"
    key = "fargater.state"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

####################################
# VPC, Subnets, Internet and NAT GW
####################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  single_nat_gateway = true
  create_vpc = true

  name = "my-private-vpc"
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
}

##############################
# ECR
##############################
resource "aws_ecr_repository" "registry" {
  name                 = "${var.app_name}-${var.env}"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "registry" {
  repository = aws_ecr_repository.registry.name

  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}

##############################
# ECS
##############################
resource "aws_ecs_cluster" "fargate" {
  name = "${var.app_name}-${var.env}"
}

resource "aws_ecs_service" "fargate" {
  name                = "${var.app_name}-${var.env}"
  cluster             = aws_ecs_cluster.fargate.id
  task_definition     = aws_ecs_task_definition.fargate.arn
  desired_count       = 0
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.fargate_ecs.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }

  depends_on = [
    aws_cloudwatch_log_group.fargate
  ]
}

resource "aws_ecs_task_definition" "fargate" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "${var.app_name}-${var.env}"

  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions    = jsonencode(local.ecs_container_definitions)
}

locals {
  ecs_container_definitions = [
    {
      image       = "${aws_ecr_repository.registry.repository_url}:latest"
      name        = "${var.app_name}-${var.env}-container",
      networkMode = "awcvpc"
      command     = var.command

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.fargate.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "fargate"
        }
      }

      environment = var.environment
    }
  ]
}

resource "aws_security_group" "fargate_ecs" {
  name        = "${var.app_name}-${var.env}"
  description = "allow outbound connections only"
  vpc_id      = module.vpc.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##############################
# IAM
##############################
##############################
# Default Task Execution Role
##############################
data "aws_iam_policy_document" "fargate_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    sid     = "ecsTaskExecutionRole"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-${var.env}-ecsTaskExecutionRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role_policy.json
}

#################################
# Allow Fargate to pull from ECR
#################################
data "aws_iam_policy_document" "ecr_image_pull" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_image_pull" {
  name        = "${var.app_name}-${var.env}-ecr-policy"
  path        = "/"
  description = "Allow Fargate to interact with ECR"

  policy = data.aws_iam_policy_document.ecr_image_pull.json
}

resource "aws_iam_role_policy_attachment" "fargate_ecr_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecr_image_pull.arn
}

##############################################
# Allow Fargate to publish logs to Cloudwatch
##############################################
resource "aws_cloudwatch_log_group" "fargate" {
  name = "/ecs/${var.app_name}-${var.env}"
}

data "aws_iam_policy_document" "log_publishing" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch"
    ]
    resources = ["arn:aws:logs:${var.region}:*:log-group:${aws_cloudwatch_log_group.fargate.name}:*"]
  }
}

resource "aws_iam_policy" "fargate_log_publishing" {
  name        = "${var.app_name}-${var.env}-log-pub"
  path        = "/"
  description = "Allow publishing to Cloudwatch"
  policy      = data.aws_iam_policy_document.log_publishing.json
}

resource "aws_iam_role_policy_attachment" "fargate_role_log_publish_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.fargate_log_publishing.arn
}

##############################
# Task Role
##############################
data "aws_iam_policy_document" "ecs_task_role_policy" {
  statement {
    effect = "Deny"
    actions = ["*"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.app_name}-${var.env}-ecsTaskRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role_policy.json
}

resource "aws_iam_policy" "ecs_task_role_policy" {
  policy = data.aws_iam_policy_document.ecs_task_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_attach" {
  role = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_policy.arn
}