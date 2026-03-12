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

cd "$(dirname "$0")/../terraform"

echo "🔴 Starte Terraform Destroy (ohne Cognito)..."

terraform destroy \
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