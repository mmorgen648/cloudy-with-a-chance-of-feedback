# ============================================================
# AWS Provider Configuration
# Verbindet Terraform mit AWS (Region eu-central-1)
# ============================================================

terraform {
  required_providers {

    # AWS Provider für Infrastruktur (EKS, VPC, RDS, etc.)
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider für eindeutige Namen (z.B. Snapshots)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}

# ============================================================
# Default AWS Provider
# Region: eu-central-1 (Frankfurt)
# Wird für fast alle Ressourcen verwendet
# ============================================================

provider "aws" {
  region = "eu-central-1"

  # Verwendet automatisch:
  # export AWS_PROFILE=cloudy
}

# ============================================================
# Zweiter AWS Provider für CloudFront Zertifikate
# WICHTIG:
# CloudFront benötigt ACM Zertifikate zwingend in us-east-1
# ============================================================

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  # Nutzt ebenfalls das gleiche AWS Profil
}