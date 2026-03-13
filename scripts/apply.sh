#!/bin/bash

# ============================================================
# Apply Script – CloudyWithAChanceOfFeedback
#
# Erstellt die gesamte Infrastruktur neu.
# Cognito bleibt erhalten – wird nicht neu erstellt.
#
# Schritte die dieses Script ausführt:
# 1. terraform apply        – Infrastruktur aufbauen
# 2. kubeconfig aktualisieren – Verbindung zum neuen EKS Cluster
# 3. aws-auth ConfigMap     – Pipeline bekommt kubectl Zugriff
# 4. ALB Controller         – Ingress braucht den Controller
# 5. Warten auf ALB         – CloudFront braucht den ALB DNS
# 6. CloudFront + Route53   – Phase 2 aufbauen
# 7. Leerer Git Commit      – triggert GitHub Actions Pipeline
#                             damit Pods deployed werden
#
# Verwendung:
# ./scripts/apply.sh
# ============================================================

set -e

# ------------------------------------------------------------
# In das Terraform Verzeichnis wechseln
# (Script liegt in scripts/ – terraform/ ist eine Ebene höher)
# ------------------------------------------------------------
cd "$(dirname "$0")/../terraform"

# ------------------------------------------------------------
# Phase 1: Infrastruktur aufbauen ohne CloudFront
#
# CloudFront braucht den ALB DNS Namen – der ALB existiert
# aber noch nicht. Deshalb bauen wir zuerst alles auf
# ausser CloudFront und Route53 Alias.
#
# eks_exists=false weil EKS zu diesem Zeitpunkt noch nicht
# existiert und die Data Sources sonst fehlschlagen.
# ------------------------------------------------------------
echo "🟢 Phase 1: Infrastruktur aufbauen (ohne CloudFront)..."
terraform apply -var="eks_exists=false" \
  -target=module.vpc \
  -target=module.security_groups \
  -target=module.eks \
  -target=module.rds \
  -target=module.acm \
  -target=module.alb_controller \
  -target=aws_acm_certificate.alb_cert \
  -target=aws_route53_record.alb_cert_validation \
  -target=aws_acm_certificate_validation.alb_cert_validation \
  -target=aws_iam_role.github_actions_eks_deploy_role \
  -target=aws_iam_role_policy.github_actions_cloudfront_invalidation \
  -target=aws_iam_role_policy_attachment.github_actions_ecr_power_user \
  -target=aws_iam_role_policy_attachment.github_actions_eks_cluster_policy \
  -target=aws_iam_role_policy_attachment.github_actions_eks_worker_node_policy

# ------------------------------------------------------------
# Schritt 2: kubeconfig aktualisieren
# Nach einem neuen EKS Cluster ist die kubeconfig veraltet.
# Dieser Befehl schreibt die neuen Verbindungsdaten.
# ------------------------------------------------------------
echo ""
echo "🔄 Aktualisiere kubeconfig..."
aws eks update-kubeconfig --name cloudy-eks --region eu-central-1

# ------------------------------------------------------------
# Schritt 3: aws-auth ConfigMap erstellen
# Trägt die EKS Node Role und die GitHub Actions Pipeline Role
# in die aws-auth ConfigMap ein.
# Ohne diesen Schritt hat die Pipeline nach dem Apply keinen
# kubectl Zugriff auf den neuen Cluster.
# ------------------------------------------------------------
echo ""
echo "🔄 Erstelle aws-auth ConfigMap..."
terraform apply -var="eks_exists=true" -var="alb_exists=false" \
  -target=kubernetes_config_map.aws_auth \
  -auto-approve

# ------------------------------------------------------------
# Schritt 4: ALB Controller installieren
# Der ALB Controller wird benötigt damit der Kubernetes Ingress
# automatisch einen AWS Application Load Balancer erstellt.
# Ohne ihn würde der Ingress keinen ALB bekommen.
# ------------------------------------------------------------
echo ""
echo "🔄 Installiere ALB Controller..."
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloudy-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# ------------------------------------------------------------
# Schritt 5: Warten bis ALB existiert
#
# Der ALB wird vom Kubernetes Ingress Controller erstellt –
# das dauert ca. 60-90 Sekunden. Wir warten bis er
# gefunden wird bevor wir CloudFront konfigurieren.
# ------------------------------------------------------------
echo ""
echo "⏳ Warte bis ALB erstellt wurde..."
for i in $(seq 1 20); do
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region eu-central-1 \
    --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-default`)].DNSName' \
    --output text 2>/dev/null || true)
  if [ -n "$ALB_DNS" ] && [ "$ALB_DNS" != "None" ]; then
    echo "✅ ALB gefunden: $ALB_DNS"
    break
  fi
  echo "   Versuch $i/20 – warte 15 Sekunden..."
  sleep 15
done

if [ -z "$ALB_DNS" ] || [ "$ALB_DNS" = "None" ]; then
  echo "❌ ALB wurde nach 5 Minuten nicht gefunden – Apply abgebrochen."
  exit 1
fi

# ------------------------------------------------------------
# Phase 2: CloudFront und Route53 aufbauen
#
# Jetzt wo EKS und ALB existieren können die Data Sources
# ausgewertet werden. CloudFront bekommt den echten ALB DNS.
# ------------------------------------------------------------
echo ""
echo "🟢 Phase 2: CloudFront und Route53 aufbauen..."
terraform apply -var="eks_exists=true" \
  -target=module.cloudfront \
  -target=aws_route53_record.cloudfront_alias

# ------------------------------------------------------------
# Schritt 7: Leerer Git Commit als Pipeline Trigger
# Kein echter Code ändert sich – der Commit dient nur dazu
# die GitHub Actions Pipeline zu starten damit die Docker
# Images gebaut und die Pods deployed werden.
# ------------------------------------------------------------
echo ""
echo "🔄 Triggere Pipeline via Git Commit..."
cd "$(dirname "$0")/.."
git commit --allow-empty -m "chore: trigger deploy nach Destroy/Apply"
git push

echo ""
echo "✅ Fertig. Pipeline läuft – Pods werden deployed."