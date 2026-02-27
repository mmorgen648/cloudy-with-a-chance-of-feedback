# ============================================================
# Security Groups Module - Main
# Zentral verwaltete Security Groups (Pflicht laut Projektstruktur)
# ============================================================

# ------------------------------------------------------------
# EKS Control Plane Security Group
# ------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security Group for EKS control plane"
  vpc_id      = var.vpc_id
}

# ------------------------------------------------------------
# RDS Security Group
# Nur EKS darf auf PostgreSQL (Port 5432) zugreifen
# ------------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Security Group for RDS PostgreSQL"
  vpc_id      = var.vpc_id
}

# ------------------------------------------------------------
# Ingress Regel: EKS → RDS (PostgreSQL Port 5432)
# ------------------------------------------------------------
resource "aws_security_group_rule" "rds_ingress_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}
