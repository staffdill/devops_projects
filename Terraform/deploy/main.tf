terraform {
  backend "local" {
    path          = "..\\tfstate\\terraform.tfstate"
    workspace_dir = "..\\tfstate"
  }
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

module "destroy_default_vpcs" {
  providers = {
    aws = aws.west
  }
  source          = "../modules/remove-default-vpc"
  aws_profile  = var.aws_profile
  aws_region  = var.aws_regions_cleanup
}