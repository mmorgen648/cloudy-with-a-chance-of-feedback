# ============================================================
# EKS Module - Main
# Erstellt den EKS Control Plane (Cluster) + nötige IAM-Rolle
# ============================================================

# ------------------------------------------------------------
# IAM Role für den EKS Cluster (Control Plane)
# AWS benötigt diese Rolle, damit EKS intern AWS-Ressourcen nutzen darf.
# ------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# AWS-managed Policy: Basis-Rechte für EKS Control Plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# AWS-managed Policy: benötigt für bestimmte VPC-Resource Aktionen (Standard bei EKS)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ------------------------------------------------------------
# Security Group für den EKS Cluster (Control Plane)
# (Minimal: nur als Basis, Regeln ergänzen wir später gezielt)
# ------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security Group for EKS control plane"
  vpc_id      = var.vpc_id
}

# ------------------------------------------------------------
# EKS Cluster (Control Plane)
# Wichtig für "kein NAT":
# - endpoint_public_access = true
#   Damit der Zugriff auf die Kubernetes API auch ohne NAT möglich ist.
# ------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Control Plane wird in Subnets platziert (mind. 2 AZs)
    subnet_ids = var.private_subnet_ids

    # API Endpoint öffentlich erreichbar (ohne NAT-Requirement für Basic-Setup)
    endpoint_public_access = true
    endpoint_private_access = false

    # Zusätzliche SG (unser Cluster-SG)
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  # Stellt sicher, dass Policies wirklich dran sind, bevor EKS erstellt wird
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}