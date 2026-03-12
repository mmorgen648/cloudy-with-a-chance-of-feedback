# ============================================================
# Cognito Modul – Main
#
# Verwaltet den bestehenden Cognito User Pool via Terraform.
# Dieser User Pool wurde ursprünglich manuell erstellt und
# wird hier per "terraform import" in den State übernommen.
#
# WICHTIG: lifecycle prevent_destroy
# Der User Pool selbst ist mit prevent_destroy = true geschützt.
# Domain, Client und Gruppe werden beim destroy gelöscht
# und beim apply automatisch neu erstellt – kein Datenverlust.
# ============================================================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ------------------------------------------------------------
# Cognito User Pool
#
# Verwaltet Benutzerkonten und Authentifizierung.
# JWT Tokens werden vom Backend validiert.
# ------------------------------------------------------------
resource "aws_cognito_user_pool" "main" {

  name = "User pool - oooflj"

  # ------------------------------------------------------------
  # Password Policy
  #
  # Mindestanforderungen für Benutzerpasswörter.
  # ------------------------------------------------------------
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # ------------------------------------------------------------
  # Auto Verified Attributes
  #
  # E-Mail wird automatisch verifiziert nach Registrierung.
  # ------------------------------------------------------------
  auto_verified_attributes = ["email"]

  # ------------------------------------------------------------
  # Prevent Destroy
  #
  # Der User Pool darf NIEMALS per terraform destroy gelöscht
  # werden. Alle Benutzer würden unwiederbringlich verloren gehen.
  # ------------------------------------------------------------
  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# ------------------------------------------------------------
# Cognito User Pool Domain
#
# Die Hosted UI Domain für den Login Flow.
# Beispiel: eu-central-1eg8otyz7b.auth.eu-central-1.amazoncognito.com
#
# Wird beim terraform destroy gelöscht und beim apply
# automatisch neu erstellt – kein Datenverlust.
# ------------------------------------------------------------
resource "aws_cognito_user_pool_domain" "main" {

  domain       = "eu-central-1eg8otyz7b"
  user_pool_id = aws_cognito_user_pool.main.id

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

# ------------------------------------------------------------
# Cognito User Pool Client
#
# Der App Client für das Frontend.
# Konfiguriert den Authorization Code Flow mit PKCE.
#
# Wird beim terraform destroy gelöscht und beim apply
# automatisch neu erstellt – kein Datenverlust.
# ------------------------------------------------------------
resource "aws_cognito_user_pool_client" "frontend" {

  name         = "cloudy-feedback-frontend"
  user_pool_id = aws_cognito_user_pool.main.id

  # ------------------------------------------------------------
  # Callback und Logout URLs
  #
  # Nach Login → Redirect zu login.html
  # Nach Logout → Redirect zu index.html
  # Beide URLs für lokal und Production definiert.
  # ------------------------------------------------------------
  callback_urls = [
    "http://localhost:8080/login.html",
    "https://cloudy.cloudhelden-projekte.com/login.html"
  ]

  logout_urls = [
    "http://localhost:8080/index.html",
    "https://cloudy.cloudhelden-projekte.com/index.html"
  ]

  # ------------------------------------------------------------
  # OAuth Flow
  #
  # Authorization Code Flow – sicherster OAuth2 Flow.
  # Token wird nie im Browser exponiert.
  # ------------------------------------------------------------
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_scopes = [
    "email",
    "openid",
    "phone"
  ]

  supported_identity_providers = ["COGNITO"]

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}

# ------------------------------------------------------------
# Cognito User Group – ROLE_ADMIN
#
# Benutzer in dieser Gruppe erhalten Admin-Rechte.
# Der JWT Token enthält cognito:groups = ["ROLE_ADMIN"]
# Das Backend prüft diese Gruppe für geschützte Endpoints.
#
# Wird beim terraform destroy gelöscht und beim apply
# automatisch neu erstellt – kein Datenverlust.
# ------------------------------------------------------------
resource "aws_cognito_user_group" "admin" {

  name         = "ROLE_ADMIN"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Admin users with full access to the feedback dashboard"

  lifecycle {
    prevent_destroy = false
    ignore_changes  = all
  }
}