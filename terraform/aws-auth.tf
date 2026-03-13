# ============================================================
# Kubernetes Service Account für Backend (Comprehend IRSA)
#
# Der Backend Pod benötigt Zugriff auf AWS Comprehend
# für die Sentiment-Analyse. Die IRSA Annotation verknüpft
# den Service Account mit der IAM Role.
# ============================================================
resource "kubernetes_service_account" "backend" {
  # count = 0 wenn eks_exists=false (Destroy) →
  # Terraform berührt diese Ressource nicht
  count = var.eks_exists ? 1 : 0
  metadata {
    name      = "backend-sa"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.comprehend.role_arn
    }
  }
  depends_on = [
    module.eks
  ]
}

# ============================================================
# Kubernetes Service Account für AWS Load Balancer Controller
#
# Helm installiert den ALB Controller mit
# serviceAccount.create=false – der Service Account muss
# deshalb von Terraform erstellt werden.
#
# Die IRSA Annotation verknüpft den Service Account mit
# der IAM Role damit der Controller AWS APIs aufrufen darf.
# ============================================================
resource "kubernetes_service_account" "alb_controller" {
  # count = 0 wenn eks_exists=false (Destroy) →
  # Terraform berührt diese Ressource nicht
  count = var.eks_exists ? 1 : 0
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.alb_controller.role_arn
    }
  }
  depends_on = [
    module.eks
  ]
}

# ============================================================
# aws-auth ConfigMap für EKS
#
# Diese ConfigMap steuert, welche IAM Rollen Zugriff
# auf den Kubernetes Cluster erhalten.
#
# REQUIREMENTS:
# Keine manuellen kubectl Schritte
# → alles wird über Terraform erzeugt.
#
# Diese Ressource liegt bewusst im Root-Modul und nicht
# in modules/eks – weil sie den Kubernetes Provider
# benötigt der erst verfügbar ist nachdem EKS vollständig
# aufgebaut und die kubeconfig aktualisiert wurde.
# ============================================================
resource "kubernetes_config_map" "aws_auth" {
  # count = 0 wenn eks_exists=false (Destroy) →
  # Terraform berührt diese Ressource nicht
  count = var.eks_exists ? 1 : 0
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: ${module.eks.node_role_arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes

- rolearn: arn:aws:iam::038217523163:role/GitHubActionsEKSDeployRole
  username: github-actions
  groups:
    - system:masters
EOF
  }

  depends_on = [
    module.eks
  ]
}