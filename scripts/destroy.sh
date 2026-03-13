#!/bin/bash

# ============================================================
# Destroy Script – CloudyWithAChanceOfFeedback
#
# Zerstört die gesamte Infrastruktur AUSSER Cognito.
# Cognito User Pool, Client, Domain und Gruppe bleiben erhalten.
#
# Verwendung:
# ./scripts/destroy.sh
#
# WARNUNG: Ohne dieses Script würde terraform destroy auch
# den Cognito User Pool löschen – alle User wären verloren.
# ============================================================

set -e

# ------------------------------------------------------------
# Ins Terraform Verzeichnis wechseln
# ------------------------------------------------------------
cd "$(dirname "$0")/../terraform"

# ------------------------------------------------------------
# Schritt 1: Kubernetes Ingress löschen
#
# Der ALB wird vom Kubernetes Ingress Controller erstellt –
# nicht von Terraform. Terraform kann ihn deshalb nicht selbst
# aufräumen. Wir löschen den Ingress jetzt während EKS noch
# vollständig läuft damit der Controller den ALB sauber abbaut.
# ------------------------------------------------------------
echo "🔄 Lösche Kubernetes Ingress..."
aws eks update-kubeconfig --name cloudy-eks --region eu-central-1 2>/dev/null || true
kubectl delete ingress --all --ignore-not-found=true 2>/dev/null || true

echo "⏳ Warte 60 Sekunden damit ALB vollständig abgebaut wird..."
sleep 60

# ------------------------------------------------------------
# Schritt 2: ALB manuell löschen falls noch vorhanden
#
# Sicherheitsnetz: Falls der ALB nach dem Ingress-Cleanup
# noch existiert, wird er hier manuell gelöscht damit
# die VPC sauber entfernt werden kann.
# ------------------------------------------------------------
echo "🔄 Prüfe ob ALB noch existiert..."
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region eu-central-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-default`)].LoadBalancerArn' \
  --output text 2>/dev/null || true)

if [ -n "$ALB_ARN" ]; then
  echo "🔄 ALB gefunden – wird gelöscht: $ALB_ARN"
  aws elbv2 delete-load-balancer --region eu-central-1 --load-balancer-arn "$ALB_ARN"
  echo "⏳ Warte 30 Sekunden auf ALB Abbau..."
  sleep 30
else
  echo "✅ Kein ALB gefunden – weiter."
fi

# ------------------------------------------------------------
# Schritt 3: k8s Security Groups löschen falls noch vorhanden
#
# Kubernetes erstellt eigene Security Groups die Terraform
# nicht kennt. Diese blockieren sonst den VPC Delete.
# ------------------------------------------------------------
echo "🔄 Prüfe k8s Security Groups..."
SG_IDS=$(aws ec2 describe-security-groups \
  --region eu-central-1 \
  --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs \
    --region eu-central-1 \
    --filters Name=isDefault,Values=false \
    --query 'Vpcs[0].VpcId' \
    --output text 2>/dev/null || echo 'none')" \
  --query 'SecurityGroups[?starts_with(GroupName, `k8s`)].GroupId' \
  --output text 2>/dev/null || true)

if [ -n "$SG_IDS" ] && [ "$SG_IDS" != "none" ]; then
  for SG_ID in $SG_IDS; do
    echo "🔄 Lösche Security Group: $SG_ID"
    aws ec2 delete-security-group --region eu-central-1 --group-id "$SG_ID" 2>/dev/null || true
  done
else
  echo "✅ Keine k8s Security Groups gefunden – weiter."
fi

# ------------------------------------------------------------
# Schritt 4: Terraform Destroy ausführen
#
# eks_exists=false sagt Terraform dass EKS und ALB
# nicht mehr existieren – Data Sources werden übersprungen.
# Cognito wird durch -target Flags ausgeschlossen.
# ------------------------------------------------------------
echo "🔴 Starte Terraform Destroy (ohne Cognito)..."
terraform destroy \
  -var="eks_exists=false" \
  -target=module.eks \
  -target=module.rds \
  -target=module.vpc \
  -target=module.cloudfront \
  -target=module.acm \
  -target=module.security_groups \
  -target=module.alb_controller \
  -target=aws_acm_certificate.alb_cert \
  -target=aws_route53_record.alb_cert_validation \
  -target=aws_acm_certificate_validation.alb_cert_validation \
  -target=aws_route53_record.cloudfront_alias \
  -target=aws_iam_role.github_actions_eks_deploy_role \
  -target=aws_iam_role_policy.github_actions_cloudfront_invalidation \
  -target=aws_iam_role_policy_attachment.github_actions_ecr_power_user \
  -target=aws_iam_role_policy_attachment.github_actions_eks_cluster_policy \
  -target=aws_iam_role_policy_attachment.github_actions_eks_worker_node_policy \
  -target=null_resource.kubernetes_bootstrap

echo "✅ Destroy abgeschlossen. Cognito bleibt erhalten."