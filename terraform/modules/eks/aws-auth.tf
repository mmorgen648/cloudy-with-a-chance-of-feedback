# ============================================================
# aws-auth ConfigMap für EKS
#
# Diese ConfigMap steuert, welche IAM Rollen Zugriff
# auf den Kubernetes Cluster erhalten.
#
# REQUIREMENTS:
# Keine manuellen kubectl Schritte
# → alles wird über Terraform erzeugt.
# ============================================================

resource "kubernetes_config_map" "aws_auth" {

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<EOF
- rolearn: arn:aws:iam::038217523163:role/cloudy-eks-node-role
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

  # Wichtig:
  # Terraform darf aws-auth erst erstellen,
  # nachdem der EKS Cluster existiert.
  depends_on = [
    aws_eks_cluster.this
  ]
}