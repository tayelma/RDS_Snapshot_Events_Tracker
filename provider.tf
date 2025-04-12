provider "aws" {
  region  = "us-east-1"
  profile = "misscloud"
}

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
  }

  backend "s3" {
    bucket = "tfstate"
    key    = "IaC/Common/Cloudwatch/AutoSnapshotsTracker/terraform.tfstate"
    region = "us-east-1"
  }
