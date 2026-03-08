# ============================================================
# AWS Load Balancer Controller – IAM Role (IRSA)
# Dieses Modul erstellt die IAM Rolle, die der Kubernetes
# ServiceAccount des ALB Controllers über OIDC annehmen darf.
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

variable "policy_arn" {
  description = "IAM Policy für den AWS Load Balancer Controller"
  type        = string
}

# ------------------------------------------------------------
# Trust Policy für IRSA
# Erlaubt dem Kubernetes ServiceAccount
# kube-system/aws-load-balancer-controller
# diese IAM Rolle anzunehmen
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
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

# ------------------------------------------------------------
# IAM Role für den ALB Controller
# ------------------------------------------------------------

resource "aws_iam_role" "alb_controller" {

  name = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# ------------------------------------------------------------
# Policy Attachment
# Verknüpft die offizielle AWS Policy
# ------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "alb_controller" {

  role       = aws_iam_role.alb_controller.name
  policy_arn = var.policy_arn
}