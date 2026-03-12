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

    # Kubernetes Provider
    # Wird benötigt, damit Terraform Ressourcen
    # direkt im Kubernetes Cluster erstellen kann
    # (z.B. aws-auth ConfigMap)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
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
# CloudFront benötigt ACM Zertifikate zwingend in us-east-1
# ============================================================

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ============================================================
# EKS Cluster Daten abrufen
#
# Diese Datenquellen erlauben Terraform,
# mit dem Kubernetes API Server zu sprechen.
# ============================================================

/* data "aws_eks_cluster" "eks" {           <------------------------
  name = "cloudy-eks"
}

data "aws_eks_cluster_auth" "eks" {
  name = "cloudy-eks"
} */

# ============================================================
# Kubernetes Provider
#
# Dieser Provider verbindet Terraform mit dem
# Kubernetes API Server des EKS Clusters.
#
# Dadurch kann Terraform Ressourcen wie
# ConfigMaps oder Secrets direkt im Cluster
# erstellen.
# ============================================================

/* provider "kubernetes" {              <----------------------------

  host = data.aws_eks_cluster.eks.endpoint

  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.eks.certificate_authority[0].data
  )

  token = data.aws_eks_cluster_auth.eks.token
} */