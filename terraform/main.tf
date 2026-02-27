# ============================================================
# Root Terraform Configuration
# Root-Modul: verbindet die einzelnen Module (VPC, Security Groups, EKS, ...)
# ============================================================

# ------------------------------------------------------------
# Root Variable: DB Password
# Wird nicht ins Git committed (kommt aus terraform.tfvars)
# ------------------------------------------------------------
variable "db_password" {
  description = "Master password for RDS PostgreSQL"
  type        = string
  sensitive   = true
}

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

# ------------------------------------------------------------
# RDS Modul
# Erstellt PostgreSQL (db.t3.micro) in Private Subnets
# REQUIREMENTS.md konform
# ------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  # Datenbankname
  db_name = "cloudydb"

  # Master User (Passwort kommt später aus tfvars!)
  db_username = "cloudyadmin"
  db_password = var.db_password

  # Netzwerk
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Security Group aus SG Modul
  rds_security_group_id = module.security_groups.rds_sg_id
}

# ------------------------------------------------------------
# RDS Outputs (Weiterleitung aus Modul)
# ------------------------------------------------------------
output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

output "rds_db_name" {
  value = module.rds.db_name
}
