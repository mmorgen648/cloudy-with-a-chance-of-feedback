# ============================================================
# Network Module Variables
# Dieses Modul erstellt die komplette Netzwerkbasis (VPC + Subnets)
# ============================================================

# VPC CIDR Block (Adressbereich des Netzwerks)
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# Public Subnet CIDRs
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

# Private Subnet CIDRs
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

# AWS Region (für Availability Zones)
variable "region" {
  description = "AWS region"
  type        = string
}