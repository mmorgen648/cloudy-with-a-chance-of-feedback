# ============================================================
# Security Groups Module - Main
# Zentral verwaltete Security Groups (Pflicht laut Projektstruktur)
# ============================================================

# ------------------------------------------------------------
# EKS Control Plane Security Group
# (Minimal: Regeln ergänzen wir später gezielt)
# ------------------------------------------------------------
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security Group for EKS control plane"
  vpc_id      = var.vpc_id
}