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
# 3. ALB Controller installieren – Ingress braucht den Controller
# 4. Leerer Git Commit      – triggert GitHub Actions Pipeline
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
# Schritt 1: Infrastruktur aufbauen
# Erstellt EKS, RDS, VPC, CloudFront, ALB Controller etc.
# Cognito bleibt erhalten – wird nicht neu erstellt.
# ------------------------------------------------------------
echo "🟢 Starte Terraform Apply..."
terraform apply -var="eks_exists=true"

# ------------------------------------------------------------
# Schritt 2: kubeconfig aktualisieren
# Nach einem neuen EKS Cluster ist die kubeconfig veraltet.
# Dieser Befehl schreibt die neuen Verbindungsdaten.
# ------------------------------------------------------------
echo ""
echo "🔄 Aktualisiere kubeconfig..."
aws eks update-kubeconfig --name cloudy-eks --region eu-central-1

# ------------------------------------------------------------
# Schritt 3: ALB Controller installieren
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
# Schritt 4: Leerer Git Commit als Pipeline Trigger
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