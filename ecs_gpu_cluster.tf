terraform {
  # Live modules pin exact provider version; generic modules let consumers pin the version.
  required_version = "= 0.12.26"

  # Live modules pin exact proqvider version; generic modules let consumers pin the version.
  required_providers {
    aws = "= 2.40.0"
  }
}



data "aws_vpc" "vpc_named_shared" {
  tags = {
    Name = "sandbox-shared"
  }
}

data "aws_subnet" "public" {
  tags = {
    Name = "sandbox-shared-private-0"
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    aws_region       = var.aws_region
    ecs_cluster_name = var.cluster_name
    vpc_name         = data.aws_vpc.vpc_named_shared.id
    log_group_name   = var.cluster_name
  }
}


module "ecs_cluster" {
  source = "git::git@github.com:gruntwork-io/module-ecs.git//modules/ecs-cluster?ref=v0.16.0"

  cluster_name     = var.cluster_name
  cluster_min_size = var.cluster_min_size
  cluster_max_size = var.cluster_max_size

  cluster_instance_ami  = var.cluster_instance_ami
  cluster_instance_type = var.cluster_instance_type

  vpc_id = data.aws_vpc.vpc_named_shared.id
  vpc_subnet_ids = [
  data.aws_subnet.public.id]
  allow_ssh                        = true
  allow_ssh_from_security_group_id = "sg-0885a25a9cb6cb701"
  cluster_instance_keypair_name    = "intel-sandbox-shared"
  cluster_instance_user_data       = data.template_file.user_data.rendered

  cluster_instance_root_volume_size = var.cluster_instance_root_volume_size
}
