# ============================================================
# Root Terraform Configuration
# Root-Modul: verbindet die einzelnen Module (VPC, Security Groups, EKS, ...)
# ============================================================

# ------------------------------------------------------------
# Root Variable: DB Password
# Wird nicht ins Git committed (kommt aus terraform.tfvars)
# ------------------------------------------------------------
variable "db_password" {
  description = "Master password for RDS PostgreSQL"
  type        = string
  sensitive   = true
}

# ------------------------------------------------------------
# Root Variable: EKS Exists
#
# Steuert ob EKS und ALB bereits existieren.
# Wird beim Destroy auf false gesetzt damit Terraform
# die Data Sources nicht auswertet die EKS und ALB
# voraussetzen.
#
# Verwendung:
# - terraform apply         → eks_exists = true (default)
# - ./scripts/destroy.sh    → eks_exists = false (automatisch gesetzt)
# ------------------------------------------------------------
variable "eks_exists" {
  description = "Ob EKS Cluster bereits existiert"
  type        = bool
  default     = true
}

# ------------------------------------------------------------
# Variable: alb_exists
# Steuert ob der ALB Data Source aktiv ist.
# Wird separat von eks_exists gesetzt weil der ALB
# erst nach dem ALB Controller + Ingress existiert.
# ------------------------------------------------------------
variable "alb_exists" {
  description = "Ob ALB bereits existiert (nach Ingress + ALB Controller)"
  type        = bool
  default     = true
}

# ------------------------------------------------------------
# Root Variable: Public Domain
#
# Domain für die öffentliche Anwendung.
# Diese Domain wird später verwendet für:
# - ACM TLS Zertifikat
# - CloudFront Distribution
# - Route53 DNS Records
#
# Beispiel:
# app.example.com
#
# Der echte Wert wird in terraform.tfvars definiert
# und NICHT im Code hardcodiert.
# ------------------------------------------------------------
variable "domain_name" {
  description = "Public domain name for the application"
  type        = string
}

# ------------------------------------------------------------
# Root Variable: Route53 Hosted Zone ID
#
# Terraform benötigt diese ID, um automatisch DNS Records
# in Route53 zu erstellen.
#
# Diese wird benötigt für:
# - ACM Zertifikatsvalidierung (DNS)
# - CloudFront DNS Record
#
# Beispiel:
# Z123456ABCDEFG
#
# Der tatsächliche Wert wird ebenfalls über terraform.tfvars
# übergeben.
# ------------------------------------------------------------
variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID used for DNS records"
  type        = string
}

# ------------------------------------------------------------
# VPC Modul (Pflicht-Struktur: modules/vpc)
# Erstellt: VPC, Public/Private Subnets, IGW, Routing
# ------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  # Gesamter VPC Adressbereich
  vpc_cidr = "10.0.0.0/16"

  # Zwei Public Subnets (2 Availability Zones)
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Zwei Private Subnets (2 Availability Zones)
  private_subnet_cidrs = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]

  # Projekt-Region (laut Vorgabe: eu-central-1)
  region = "eu-central-1"
}

# ------------------------------------------------------------
# Security Groups Modul (Pflicht-Struktur: modules/security-groups)
# Erstellt zentral die Security Groups (EKS, später RDS, ALB, ...)
# ------------------------------------------------------------
module "security_groups" {
  source = "./modules/security-groups"

  # Security Groups werden in der VPC erstellt
  vpc_id = module.vpc.vpc_id

  # Für sprechende Namen (z.B. cloudy-eks-cluster-sg)
  cluster_name = "cloudy-eks"
}

# ------------------------------------------------------------
# EKS Modul (Pflicht-Struktur: modules/eks)
# Erstellt den EKS Control Plane (Cluster). Node Group kommt als nächster Schritt.
# WICHTIG laut Vorgabe: Nodes sollen in Public Subnets laufen (spart NAT).
# ------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  # Eindeutiger Cluster-Name
  cluster_name = "cloudy-eks"

  # Public Subnets für EKS (Vorgabe: Standard Public Subnets)
  public_subnet_ids = module.vpc.public_subnet_ids

  # VPC Referenz (z.B. für spätere EKS/Node/Ingress Regeln)
  vpc_id = module.vpc.vpc_id

  # Security Group für den EKS Control Plane kommt aus dem zentralen SG-Modul
  cluster_security_group_id = module.security_groups.eks_cluster_sg_id

  # Projekt-Region
  region = "eu-central-1"
}

# ------------------------------------------------------------
# AWS Load Balancer Controller – IAM Role (IRSA)
# REQUIREMENTS.md konform:
# Infrastruktur wird vollständig über Terraform verwaltet
#
# Dieses Modul erstellt:
# - IAM Role für den AWS Load Balancer Controller
# - Trust Relationship mit dem EKS OIDC Provider
# - Policy Attachment zur offiziellen AWS Controller Policy
#
# Der Kubernetes ServiceAccount:
# kube-system/aws-load-balancer-controller
# darf diese Rolle über IRSA annehmen.
# ------------------------------------------------------------
module "alb_controller" {

  source = "./modules/alb-controller"

  # Cluster Name (für sprechende IAM Rollennamen)
  cluster_name = "cloudy-eks"

  # OIDC Informationen aus dem EKS Modul
  # Diese werden vom EKS Modul exportiert
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  # Bereits existierende AWS Policy für den Controller
  # Diese wurde zuvor einmalig erstellt
  policy_arn = "arn:aws:iam::038217523163:policy/AWSLoadBalancerControllerIAMPolicy"
}

# ------------------------------------------------------------
# RDS Modul
# Erstellt PostgreSQL (db.t3.micro) in Private Subnets
# REQUIREMENTS.md konform
# ------------------------------------------------------------
module "rds" {
  source = "./modules/rds"

  # Datenbankname
  db_name = "cloudydb"

  # Master User (Passwort kommt später aus tfvars!)
  db_username = "cloudyadmin"
  db_password = var.db_password

  # Netzwerk
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Security Group aus SG Modul
  rds_security_group_id = module.security_groups.rds_sg_id
}

# ------------------------------------------------------------
# ACM Modul
#
# Erstellt ein TLS Zertifikat für CloudFront.
#
# REQUIREMENTS.md:
# CloudFront benötigt zwingend ein Zertifikat aus us-east-1.
#
# Deshalb wird hier der AWS Provider Alias an das Modul
# übergeben.
#
# Dadurch nutzt das Modul automatisch:
# provider "aws" { alias = "us_east_1" }
# ------------------------------------------------------------
module "acm" {

  source = "./modules/acm"

  # Übergibt Provider Alias an das Modul
  providers = {
    aws = aws.us_east_1
  }

  # Öffentliche Domain der Anwendung
  domain_name = var.domain_name

  # Route53 Hosted Zone
  hosted_zone_id = var.hosted_zone_id
}

# ------------------------------------------------------------
# ACM Zertifikat für ALB (Region eu-central-1)
#
# Dieses Zertifikat wird vom Application Load Balancer
# verwendet, damit CloudFront über HTTPS zum ALB sprechen kann.
#
# Checkliste verlangt:
# CloudFront → HTTPS → ALB
# ------------------------------------------------------------
resource "aws_acm_certificate" "alb_cert" {

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ------------------------------------------------------------
# Route53 DNS Record für ALB Zertifikatsvalidierung
#
# ACM gibt einen DNS Record zurück, der erstellt werden muss,
# damit das Zertifikat validiert werden kann.
# Terraform erstellt diesen Record automatisch.
# ------------------------------------------------------------
resource "aws_route53_record" "alb_cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options :
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

# ------------------------------------------------------------
# ACM Zertifikatsvalidierung für ALB
#
# Terraform wartet hier, bis Route53 den DNS Record
# propagiert hat und das Zertifikat erfolgreich validiert
# wurde.
# ------------------------------------------------------------
resource "aws_acm_certificate_validation" "alb_cert_validation" {

  certificate_arn = aws_acm_certificate.alb_cert.arn

  validation_record_fqdns = [
    for record in aws_route53_record.alb_cert_validation :
    record.fqdn
  ]
}

# ------------------------------------------------------------
# ALB Data Source
#
# Der ALB wird nicht direkt von Terraform erstellt,
# sondern vom Kubernetes Ingress über den
# AWS Load Balancer Controller.
#
# Diese Data Source liest den aktuell existierenden
# ALB aus AWS, damit wir seinen DNS Namen automatisch
# verwenden können.
#
# count = 1 → wenn EKS/ALB existiert (normaler Apply)
# count = 0 → wenn EKS/ALB nicht existiert (Destroy)
# ------------------------------------------------------------
data "aws_lb" "eks_ingress" {
  count = var.alb_exists ? 1 : 0
  tags = {
    "elbv2.k8s.aws/cluster" = "cloudy-eks"
  }
}
# ------------------------------------------------------------
# CloudFront Modul
#
# CloudFront sitzt vor dem ALB und stellt HTTPS + CDN bereit.
# ------------------------------------------------------------
module "cloudfront" {

  source = "./modules/cloudfront"

  domain_name = var.domain_name

  # ACM Zertifikat aus dem ACM Modul
  acm_certificate_arn = module.acm.aws_acm_certificate_arn

  # ALB DNS Name – automatisch aus AWS gelesen wenn EKS existiert
  # Platzhalter wird gesetzt wenn eks_exists = false (Destroy)
  alb_dns_name = var.alb_exists ? data.aws_lb.eks_ingress[0].dns_name : "placeholder.example.com"
}

# ------------------------------------------------------------
# RDS Outputs (Weiterleitung aus Modul)
# ------------------------------------------------------------
output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_port" {
  value = module.rds.db_port
}

output "rds_db_name" {
  value = module.rds.db_name
}

# ------------------------------------------------------------
# Cognito Modul
#
# Übernimmt den bestehenden Cognito User Pool in Terraform.
# Der User Pool wurde ursprünglich manuell erstellt und wird
# per "terraform import" in den State übernommen.
#
# WICHTIG: prevent_destroy = true im Modul verhindert
# dass der User Pool beim terraform destroy gelöscht wird.
# ------------------------------------------------------------
module "cognito" {
  source      = "./modules/cognito"
  domain_name = var.domain_name
}

# ------------------------------------------------------------
# Route53 DNS Record
#
# Dieser Record verbindet deine öffentliche Domain
#
# cloudy.cloudhelden-projekte.com
#
# mit der CloudFront Distribution.
#
# Dadurch ist die Anwendung später erreichbar über:
#
# https://cloudy.cloudhelden-projekte.com
#
# Terraform liest automatisch:
# - CloudFront Domain
# - CloudFront Hosted Zone
# ------------------------------------------------------------
resource "aws_route53_record" "cloudfront_alias" {

  zone_id = var.hosted_zone_id

  name = var.domain_name
  type = "A"

  alias {
    name                   = module.cloudfront.cloudfront_domain_name
    zone_id                = module.cloudfront.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
