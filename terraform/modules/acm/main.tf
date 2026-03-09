# ============================================================
# ACM Modul
#
# Dieses Modul erstellt ein TLS Zertifikat für CloudFront
# und validiert es automatisch über Route53 DNS Records.
#
# WICHTIG:
# CloudFront akzeptiert Zertifikate ausschließlich aus
# der Region us-east-1.
#
# Deshalb wird hier der Provider Alias "aws.us_east_1"
# verwendet.
# ============================================================


# ------------------------------------------------------------
# Required Providers
#
# Dieser Block definiert, welchen Provider dieses Modul nutzt.
# Dadurch weiß Terraform, dass das Modul den AWS Provider
# erwartet, der vom Root-Modul übergeben wird.
# ------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ============================================================
# ACM Certificate
#
# Erstellt das eigentliche TLS Zertifikat.
# Die Validierung erfolgt über DNS.
# ============================================================

resource "aws_acm_certificate" "cloudfront_cert" {

  # Provider Alias → us-east-1
  provider = aws

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    # verhindert Downtime bei Zertifikatserneuerung
    create_before_destroy = true
  }

  tags = {
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ============================================================
# Route53 DNS Record für Zertifikatsvalidierung
#
# ACM gibt einen speziellen DNS Record zurück,
# der in Route53 angelegt werden muss.
#
# Terraform liest diese Daten aus dem Zertifikat
# und erstellt den Record automatisch.
# ============================================================

resource "aws_route53_record" "cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.hosted_zone_id

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]

  ttl = 60
}



# ============================================================
# ACM Zertifikatsvalidierung
#
# Terraform wartet hier, bis Route53 den DNS Record
# propagiert hat und das Zertifikat erfolgreich validiert
# wurde.
# ============================================================

resource "aws_acm_certificate_validation" "cloudfront_cert_validation" {

  provider = aws

  certificate_arn = aws_acm_certificate.cloudfront_cert.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation :
    record.fqdn
  ]
}

# ------------------------------------------------------------
# Output: ACM Certificate ARN
#
# Dieser Output stellt die ARN des Zertifikats dem Root-Modul
# zur Verfügung, damit CloudFront dieses Zertifikat nutzen kann.
# ------------------------------------------------------------
output "aws_acm_certificate_arn" {
  value = aws_acm_certificate.cloudfront_cert.arn
}
