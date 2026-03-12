# ============================================================
# Cognito Modul – Outputs
#
# Gibt wichtige Werte des Cognito User Pools zurück
# damit andere Module (z.B. Backend) darauf zugreifen können.
# ============================================================

# ------------------------------------------------------------
# User Pool ID
#
# Wird vom Backend für die JWT Validierung benötigt.
# Beispiel: eu-central-1_EG8oTyz7B
# ------------------------------------------------------------
output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

# ------------------------------------------------------------
# User Pool Client ID
#
# Wird vom Frontend für den Login Flow benötigt.
# Beispiel: 5gc47l6rh621jdl9ai7bfli2qv
# ------------------------------------------------------------
output "client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.frontend.id
}

# ------------------------------------------------------------
# Cognito Domain
#
# Die Auth Domain für den Hosted UI Login.
# Beispiel: eu-central-1eg8otyz7b.auth.eu-central-1.amazoncognito.com
# ------------------------------------------------------------
output "cognito_domain" {
  description = "Cognito hosted UI domain"
  value       = "${aws_cognito_user_pool_domain.main.domain}.auth.eu-central-1.amazoncognito.com"
}