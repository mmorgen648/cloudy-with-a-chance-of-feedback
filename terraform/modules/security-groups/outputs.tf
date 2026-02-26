# ============================================================
# Security Groups Module Outputs
# ============================================================

output "eks_cluster_sg_id" {
  description = "Security group ID for the EKS control plane"
  value       = aws_security_group.eks_cluster_sg.id
}