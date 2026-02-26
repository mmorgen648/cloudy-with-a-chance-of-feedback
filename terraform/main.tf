# ============================================================
# Root Terraform Configuration
# Bindet das Network Modul ein
# ============================================================

module "network" {
  source = "./modules/network"

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

  region = "eu-central-1"
}

# ============================================================
# EKS Modul (Woche 2)
# ============================================================

module "eks" {
  source = "./modules/eks"

  # Eindeutiger Cluster-Name
  cluster_name = "cloudy-eks"

  # Wir nutzen die PRIVATE Subnets für Worker Nodes
  private_subnet_ids = module.network.private_subnet_ids

  # VPC Referenz (für Security Groups etc.)
  vpc_id = module.network.vpc_id

  region = "eu-central-1"
}