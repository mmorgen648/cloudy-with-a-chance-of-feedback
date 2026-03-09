# ============================================================
# CloudFront Modul
#
# Dieses Modul erstellt später die CloudFront Distribution,
# die vor dem ALB stehen wird.
#
# Architektur laut REQUIREMENTS.md:
#
# Route53
#    ↓
# CloudFront
#    ↓
# ALB (Ingress)
#    ↓
# EKS Services
# ============================================================


# ------------------------------------------------------------
# Required Providers
#
# Das Modul erwartet den AWS Provider aus dem Root Modul.
# Der Provider wird später über main.tf übergeben.
# ------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ------------------------------------------------------------
# CloudFront Distribution
#
# Erstellt die CloudFront Distribution vor dem ALB.
# CloudFront fungiert als globaler Edge Layer.
# ------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {

  enabled = true

  # Domain Alias (z.B. cloudy.cloudhelden-projekte.com)
  aliases = [var.domain_name]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"

      origin_ssl_protocols = [
        "TLSv1.2"
      ]
    }
  }

  # ------------------------------------------------------------
  # Default Cache Behavior
  #
  # Definiert, wie CloudFront Requests behandelt und
  # an den Origin (ALB) weiterleitet.
  # ------------------------------------------------------------
  default_cache_behavior {

    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
      "PUT",
      "POST",
      "PATCH",
      "DELETE"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    forwarded_values {

  # ------------------------------------------------------------
  # Host Header an ALB weiterleiten
  #
  # CloudFront muss den Host Header weiterleiten,
  # damit der ALB das richtige Zertifikat verwenden kann.
  # Beispiel:
  # Host: cloudy.cloudhelden-projekte.com
  # ------------------------------------------------------------
        headers = ["Host"]

        query_string = true

        cookies {
            forward = "all"
        }
    }
  }

# ------------------------------------------------------------
# API Cache Behavior
#
# Laut Projekt-Checkliste dürfen API Requests NICHT gecached
# werden. Deshalb wird für /api/* ein eigener Behavior mit
# TTL = 0 definiert.
#
# Dadurch werden API Requests immer direkt an den Origin
# (ALB → Backend Service) weitergeleitet.
# ------------------------------------------------------------
ordered_cache_behavior {

  path_pattern = "/api/*"

  target_origin_id = "alb-origin"

  viewer_protocol_policy = "redirect-to-https"

  allowed_methods = [
    "GET",
    "HEAD",
    "OPTIONS",
    "PUT",
    "POST",
    "PATCH",
    "DELETE"
  ]

  cached_methods = [
    "GET",
    "HEAD"
  ]

  forwarded_values {

    query_string = true

    headers = [
      "Host"
    ]

    cookies {
      forward = "all"
    }
  }

  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 0
}
  # ------------------------------------------------------------
  # Viewer Certificate
  #
  # CloudFront nutzt das ACM Zertifikat für HTTPS.
  # Das Zertifikat muss in us-east-1 erstellt worden sein.
  # ------------------------------------------------------------
  viewer_certificate {

    acm_certificate_arn = var.acm_certificate_arn

    ssl_support_method = "sni-only"

    minimum_protocol_version = "TLSv1.2_2021"
  }

  # ------------------------------------------------------------
  # Restrictions
  #
  # Keine Geo-Einschränkungen für die Distribution.
  # ------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ------------------------------------------------------------
  # Price Class
  #
  # Limitiert Edge Locations auf Europa und USA,
  # reduziert Kosten gegenüber globaler Distribution.
  # ------------------------------------------------------------
  price_class = "PriceClass_100"
}
