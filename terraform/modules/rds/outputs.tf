# ============================================================
# RDS Module - Outputs
# Gibt wichtige Informationen (Endpoint, Port, DB Name) zurück
# ============================================================

# RDS Endpoint (Host)
output "db_endpoint" {
  description = "RDS endpoint (host)"
  value       = aws_db_instance.this.address
}

# RDS Port (PostgreSQL Standard)
output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

# DB Name
output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}
