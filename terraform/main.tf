# ============================================================
# Root Terraform Configuration
# Root-Modul: verbindet die einzelnen Module (VPC, Security Groups, EKS, ...)
# ============================================================

# ------------------------------------------------------------
# VPC Modul (Pflicht-Struktur: modules/vpc)
# Erstellt: VPC, Public/Private Subnets, IGW, Routing
# ------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  # Gesamter VPC Adressbereich
  vpc_cidr = "10.0.0.0/16"

  # Zwei Public Subnets (2 Availability Zones)
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Zwei Private Subnets (2 Availability Zones)
  private_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  # Projekt-Region (laut Vorgabe: eu-central-1)
  region = "eu-central-1"
}

# ------------------------------------------------------------
# Security Groups Modul (Pflicht-Struktur: modules/security-groups)
# Erstellt zentral die Security Groups (EKS, später RDS, ALB, ...)
# ------------------------------------------------------------
module "security_groups" {
  source = "./modules/security-groups"

  # Security Groups werden in der VPC erstellt
  vpc_id = module.vpc.vpc_id

  # Für sprechende Namen (z.B. cloudy-eks-cluster-sg)
  cluster_name = "cloudy-eks"
}

# ------------------------------------------------------------
# EKS Modul (Pflicht-Struktur: modules/eks)
# Erstellt den EKS Control Plane (Cluster). Node Group kommt als nächster Schritt.
# WICHTIG laut Vorgabe: Nodes sollen in Public Subnets laufen (spart NAT).
# ------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  # Eindeutiger Cluster-Name
  cluster_name = "cloudy-eks"

  # Public Subnets für EKS (Vorgabe: Standard Public Subnets)
  public_subnet_ids = module.vpc.public_subnet_ids

  # VPC Referenz (z.B. für spätere EKS/Node/Ingress Regeln)
  vpc_id = module.vpc.vpc_id

  # Security Group für den EKS Control Plane kommt aus dem zentralen SG-Modul
  cluster_security_group_id = module.security_groups.eks_cluster_sg_id

  # Projekt-Region
  region = "eu-central-1"
}