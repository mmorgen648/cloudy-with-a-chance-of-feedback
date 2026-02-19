#############################################
# providers.tf
# Definiert Terraform Version + AWS Provider
#############################################

terraform {
  # Mindestversion von Terraform
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#############################################
# AWS Provider Konfiguration
#############################################

provider "aws" {
  region = "eu-central-1"
}
