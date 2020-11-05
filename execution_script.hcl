# this is copy-paste stuff from reference repo, boilerplate stuff, nothing custom here
locals {
  # this auto loads environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl"))

  # extracts out common variables for reuse
  env = local.environment_vars.locals.environment
}


terraform {
  # This is a link to the corresponding safeXai code. This will be customized by us. Note we use a specific version
  source = "git::git@github.com:AICradle/infra-modules-intel.git//video-pipeline?ref=0.0.3"
  # Can switch source to local directory for local development
  #source = "/Users/danielrich/aicradle/infra-modules-intel//video-pipeline"
  #source = "/Users/joshteambanjo.com/Projects/Banjo/python/infra-modules-intel//video-pipeline"
}

# When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
dependencies {
  paths = [
    "./../services/ecs-gpu-cluster",
  ]
}
# Include all settings from root terragrunt.hcl file (copy-paste again, boilerplate)
include {
  path = find_in_parent_folders()
}


# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  ecs_cluster_name           = "intel-gpu-ecs-cluster"
  terraform_state_aws_region = "us-west-2"
  terraform_state_s3_bucket  = "banjo-intel-terraform-states-eng-admin"
  vpc_name                   = "sandbox-shared"
  input_s3                   = "crockpot/josh/in/CHK005/"
  output_s3                  = "crockpot/josh/out/CHK005/"
  pipeline                   = "simulation_intersection_yolov3"
}
