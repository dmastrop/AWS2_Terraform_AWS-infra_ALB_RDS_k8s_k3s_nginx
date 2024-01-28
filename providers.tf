# this is root/providers.tf in AWS2 project. This is very similar to the providers.tf file in root/providers.tf in the k8s workspace project

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  #region = "us-east-1"
  region = var.aws_region
}
