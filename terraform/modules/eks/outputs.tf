# ============================================================
# EKS Module Outputs
# Gibt wichtige Werte an das Root-Modul weiter
# ============================================================

# ------------------------------------------------------------
# Basis-Infos zum Cluster
# ------------------------------------------------------------
output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.this.endpoint
}

# ------------------------------------------------------------
# Zertifikat (Base64) für den Kubernetes API Zugriff
# Wird später z.B. für kubeconfig / Provider-Konfiguration benötigt
# ------------------------------------------------------------
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

# ------------------------------------------------------------
# Security Group des EKS Control Plane
# WICHTIG: Die SG wird NICHT im EKS-Modul erstellt,
# sondern zentral im Modul 'security-groups' und hier als Variable übergeben.
# ------------------------------------------------------------
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane"
  value       = var.cluster_security_group_id
}

# ------------------------------------------------------------
# IAM Rolle des Control Plane
# ------------------------------------------------------------
output "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane"
  value       = aws_iam_role.eks_cluster_role.arn
}

# ============================================================
# NEU: OIDC Provider Informationen
# ------------------------------------------------------------
# Diese Outputs werden vom Root-Modul benötigt,
# damit andere Module (z.B. AWS Load Balancer Controller)
# IAM Roles für Kubernetes ServiceAccounts erstellen können.
#
# Dadurch kann Terraform IRSA Rollen automatisch konfigurieren.
# ============================================================

# ARN des OIDC Providers
output "oidc_provider_arn" {
  description = "OIDC provider ARN used for IRSA (IAM Roles for Service Accounts)"
  value       = aws_iam_openid_connect_provider.eks.arn
}

# URL des OIDC Providers
output "oidc_provider_url" {
  description = "OIDC provider URL used for IRSA trust policies"
  value       = aws_iam_openid_connect_provider.eks.url
}