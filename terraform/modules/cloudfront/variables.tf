# ============================================================
# CloudFront Modul – Eingabevariablen
# ============================================================

# ------------------------------------------------------------
# Domain Name
#
# Öffentliche Domain der Anwendung.
# Diese Domain wird später als CloudFront Alias verwendet.
#
# Beispiel:
# app.example.com
# ------------------------------------------------------------
variable "domain_name" {
  description = "Public domain name used for CloudFront"
  type        = string
}

# ------------------------------------------------------------
# ACM Certificate ARN
#
# ARN des ACM Zertifikats, das für HTTPS in CloudFront
# verwendet wird.
#
# Das Zertifikat muss laut AWS-Anforderung in
# der Region us-east-1 liegen.
# ------------------------------------------------------------
variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate used by CloudFront"
  type        = string
}

# ------------------------------------------------------------
# ALB DNS Name
#
# DNS Name des Application Load Balancers.
# CloudFront nutzt diesen später als Origin.
#
# Beispiel:
# internal-cloudy-alb-123456.eu-central-1.elb.amazonaws.com
# ------------------------------------------------------------
variable "alb_dns_name" {
  description = "DNS name of the ALB used as CloudFront origin"
  type        = string
}