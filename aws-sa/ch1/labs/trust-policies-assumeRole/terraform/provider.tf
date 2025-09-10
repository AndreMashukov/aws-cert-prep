# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = {
      Lab         = var.lab_name
      Environment = "learning"
      CreatedBy   = "aws-cert-prep-lab"
      ManagedBy   = "terraform"
    }
  }
}

# Configure the random provider for unique resource naming
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}
