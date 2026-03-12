# ============================================================
# Cognito Modul – Variables
#
# Eingabevariablen für das Cognito Modul.
# Alle Werte werden aus dem Root Modul übergeben.
# ============================================================

# ------------------------------------------------------------
# Domain Name
#
# Die öffentliche Domain der Anwendung.
# Wird als Callback und Logout URL verwendet.
# Beispiel: cloudy.cloudhelden-projekte.com
# ------------------------------------------------------------
variable "domain_name" {
  description = "Public domain name of the application"
  type        = string
}