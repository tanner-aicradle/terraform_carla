# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE REMOTE STATE STORAGE
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_version = "= 0.12.26"

  # Live modules pin exact proqvider version; generic modules let consumers pin the version.
  required_providers {
    aws = "= 2.40.0"
  }
}



# https://www.terraform.io/docs/providers/aws/d/vpc.html
data "aws_vpc" "vpc_named_shared" {
  tags = {
    Name = "sandbox-shared"
  }
}

# https://www.terraform.io/docs/providers/aws/d/availability_zones.html
data "aws_availability_zones" "available" {
  state = "available"
}


# https://www.terraform.io/docs/providers/aws/d/subnet_ids.html
data "aws_subnet" "public" {
  tags = {
    Name = "sandbox-shared-private-0"
  }
}

data "aws_iam_role" "ecs_role" {
  name = "${var.ecs_cluster_name}-instance"
}

data "aws_iam_policy_document" "s3_full" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
    "*"]
  }
}

data "aws_iam_policy_document" "push_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
    "arn:aws:logs:*:*:*"]
  }
}


resource "aws_ecs_service" "service" {
  name                = var.application_prefix
  cluster             = var.ecs_cluster_name
  desired_count       = 1
  task_definition     = aws_ecs_task_definition.intel_video_ecs.arn
  scheduling_strategy = "REPLICA"
  # 50 percent must be healthy during deploys
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100
}



resource "aws_ecs_task_definition" "intel_video_ecs" {
  family = var.application_prefix
  container_definitions = templatefile("task_definition.json", {
    application_prefix = var.application_prefix
    aws_region         = var.aws_region
    ecs_cluster_name   = var.ecs_cluster_name
    pipeline           = var.pipeline
    output_s3          = var.output_s3
    input_s3           = var.input_s3
  })

  tags = var.default_tags

}


resource "aws_iam_role_policy" "ecs_logs" {
  role   = data.aws_iam_role.ecs_role.id
  policy = data.aws_iam_policy_document.push_logs.json
}


resource "aws_iam_role_policy" "ecs_s3" {
  role   = data.aws_iam_role.ecs_role.id
  policy = data.aws_iam_policy_document.s3_full.json
}
