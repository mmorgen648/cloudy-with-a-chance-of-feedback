# ============================================================
# RDS Module - Main
# Erstellt:
# - DB Subnet Group (nur Private Subnets)
# - PostgreSQL RDS Instance (db.t3.micro laut REQUIREMENTS.md)
# ============================================================

# ------------------------------------------------------------
# Zufalls-Suffix für Snapshot-Namen
# Stabil (ändert sich nicht bei jedem Plan), verhindert Kollisionen
# ------------------------------------------------------------
resource "random_id" "snapshot_suffix" {
  byte_length = 4
}

# ------------------------------------------------------------
# DB Subnet Group
# RDS darf laut REQUIREMENTS.md nur in Private Subnets laufen
# ------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "cloudy-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  description = "Subnet group for Cloudy RDS (private subnets only)"

  tags = {
    Name = "cloudy-rds-subnet-group"
  }
}

# ------------------------------------------------------------
# RDS PostgreSQL Instance
# Vorgaben:
# - db.t3.micro
# - Private Subnets
# - Keine Public Accessibility
# - Kein Overengineering
# ------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier                = "cloudy-postgres"
  engine                    = "postgres"
  engine_version            = "15"
  instance_class            = "db.t3.micro"
  allocated_storage         = 20
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  db_subnet_group_name      = aws_db_subnet_group.this.name
  vpc_security_group_ids    = [var.rds_security_group_id]
  publicly_accessible       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "cloudy-postgres-final-${random_id.snapshot_suffix.hex}"
  deletion_protection       = false
  multi_az                  = false

  tags = {
    Name = "cloudy-postgres"
  }
}
