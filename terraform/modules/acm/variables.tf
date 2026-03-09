# ============================================================
# ACM Modul – Eingabevariablen
#
# Dieses Modul erstellt ein ACM Zertifikat für CloudFront
# und validiert es automatisch über Route53 DNS Records.
#
# WICHTIG:
# CloudFront akzeptiert Zertifikate ausschließlich aus
# der Region us-east-1.
# ============================================================


# ------------------------------------------------------------
# Domain Name
#
# Öffentliche Domain, für die das TLS Zertifikat erstellt wird.
#
# Beispiel:
# example.com
# oder
# app.example.com
#
# Der konkrete Wert wird NICHT im Modul definiert,
# sondern später in der Root Terraform Konfiguration
# übergeben (main.tf / terraform.tfvars).
# ------------------------------------------------------------
variable "domain_name" {
  description = "Domain name for which the ACM certificate should be created"
  type        = string
}


# ------------------------------------------------------------
# Route53 Hosted Zone ID
#
# Terraform benötigt diese ID, um automatisch den DNS Record
# für die ACM Zertifikatsvalidierung zu erstellen.
#
# Beispiel:
# Z123456ABCDEFG
#
# Diese ID gehört zur Route53 Hosted Zone der Domain.
# Der tatsächliche Wert wird ebenfalls außerhalb des
# Moduls übergeben.
# ------------------------------------------------------------
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID used for ACM DNS validation"
  type        = string
}