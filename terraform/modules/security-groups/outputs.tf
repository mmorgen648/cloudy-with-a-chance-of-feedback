# ============================================================
# Security Groups Module Outputs
# ============================================================

# ------------------------------------------------------------
# EKS Cluster Security Group ID
# ------------------------------------------------------------
output "eks_cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.eks_cluster_sg.id
}

# ------------------------------------------------------------
# RDS Security Group ID
# ------------------------------------------------------------
output "rds_sg_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_sg.id
}
