# ============================================================
# RDS Module - Variables
# Definiert alle Eingabeparameter für die PostgreSQL Datenbank
# ============================================================

# Name der Datenbank (z.B. cloudydb)
variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
}

# Master Username für die Datenbank
# (Passwort wird später NICHT hartcodiert!)
variable "db_username" {
  description = "Master username for PostgreSQL"
  type        = string
}

# Master Passwort für die Datenbank
# WICHTIG: Wird NICHT ins Git committed (kommt später aus tfvars oder Secret)
variable "db_password" {
  description = "Master password for PostgreSQL"
  type        = string
  sensitive   = true
}

# VPC ID (RDS muss in derselben VPC laufen)
variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

# Private Subnets (laut REQUIREMENTS.md Pflicht)
variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

# Security Group ID für RDS
variable "rds_security_group_id" {
  description = "Security Group ID assigned to RDS instance"
  type        = string
}
