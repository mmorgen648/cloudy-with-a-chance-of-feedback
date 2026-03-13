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
#
# count = 1 → wenn EKS existiert (normaler Apply)
# count = 0 → wenn EKS nicht existiert (Destroy)
# ============================================================
data "aws_eks_cluster" "eks" {
  count = var.eks_exists ? 1 : 0
  name  = "cloudy-eks"
}

data "aws_eks_cluster_auth" "eks" {
  count = var.eks_exists ? 1 : 0
  name  = "cloudy-eks"
}

# ============================================================
# Kubernetes Provider
#
# Dieser Provider verbindet Terraform mit dem
# Kubernetes API Server des EKS Clusters.
#
# Wenn eks_exists = false (Destroy):
# - leere Werte werden gesetzt
# - Terraform kommuniziert nicht mit Kubernetes
# - kubernetes_config_map wird beim Destroy nicht berührt
# ============================================================
provider "kubernetes" {
  host = var.eks_exists ? data.aws_eks_cluster.eks[0].endpoint : ""
  cluster_ca_certificate = var.eks_exists ? base64decode(
    data.aws_eks_cluster.eks[0].certificate_authority[0].data
  ) : ""
  token = var.eks_exists ? data.aws_eks_cluster_auth.eks[0].token : ""
}