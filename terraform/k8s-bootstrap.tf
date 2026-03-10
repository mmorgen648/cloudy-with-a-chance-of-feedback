# ------------------------------------------------------------
# Kubernetes Bootstrap
#
# Diese Ressource sorgt dafür, dass nach einem neuen
# Terraform Apply automatisch:
#
# 1. aws-auth ConfigMap gesetzt wird
# 2. Kubernetes Manifeste angewendet werden
#
# Dadurch startet der Cluster nach:
# terraform destroy
# terraform apply
#
# automatisch mit:
# - Backend Deployment
# - Frontend Deployment
# - Services
# - Ingress
# ------------------------------------------------------------

resource "null_resource" "kubernetes_bootstrap" {

  depends_on = [
    module.eks
  ]

  provisioner "local-exec" {

    command = <<EOT
kubectl apply -f ../k8s/aws-auth.yaml
kubectl apply -f ../k8s/
EOT

  }

}