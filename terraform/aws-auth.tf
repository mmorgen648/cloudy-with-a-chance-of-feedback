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