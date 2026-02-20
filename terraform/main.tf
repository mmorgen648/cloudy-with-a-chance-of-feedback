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