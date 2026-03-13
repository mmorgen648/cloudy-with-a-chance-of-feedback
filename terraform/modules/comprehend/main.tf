# ============================================================
# Comprehend IAM Role (IRSA)
#
# Dieses Modul erstellt die IAM Rolle die der Kubernetes
# ServiceAccount des Backends über OIDC annehmen darf
# um AWS Comprehend für Sentiment-Analyse aufzurufen.
#
# Die OIDC ID wird dynamisch aus dem EKS Modul bezogen –
# damit funktioniert die Role nach jedem Destroy/Apply.
# ============================================================

variable "cluster_name" {
  description = "Name des EKS Clusters"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN des EKS OIDC Providers"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL des EKS OIDC Providers"
  type        = string
}

# ------------------------------------------------------------
# Trust Policy für IRSA
# Erlaubt dem Kubernetes ServiceAccount
# default/backend-sa diese IAM Rolle anzunehmen
# ------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:default:backend-sa"
      ]
    }
  }
}

# ------------------------------------------------------------
# IAM Role für den Backend Pod
# ------------------------------------------------------------
resource "aws_iam_role" "comprehend" {
  name               = "${var.cluster_name}-comprehend-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# ------------------------------------------------------------
# Policy Attachment
# Verknüpft die AWS Managed ComprehendFullAccess Policy
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "comprehend" {
  role       = aws_iam_role.comprehend.name
  policy_arn = "arn:aws:iam::aws:policy/ComprehendFullAccess"
}

# ------------------------------------------------------------
# Output: IAM Role ARN
# Wird von aws-auth.tf für den Service Account benötigt
# ------------------------------------------------------------
output "role_arn" {
  description = "ARN der IAM Role für den Backend Comprehend Zugriff"
  value       = aws_iam_role.comprehend.arn
}