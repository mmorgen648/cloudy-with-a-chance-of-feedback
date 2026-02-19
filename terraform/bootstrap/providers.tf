#############################################
# providers.tf
# Definiert Terraform Version + AWS Provider
#############################################

terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "cloudy-feedback-tfstate-eu-central-1"
    key            = "bootstrap/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cloudy-feedback-terraform-locks"
    encrypt        = true
  }

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
