# ------------------------------------------------------------
# CloudFront Domain Name
#
# Beispiel:
# d123abcd.cloudfront.net
#
# Wird benötigt für Route53 DNS Alias
# ------------------------------------------------------------
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

# ------------------------------------------------------------
# CloudFront Hosted Zone ID
#
# Wird benötigt für Route53 Alias Records
# ------------------------------------------------------------
output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.this.hosted_zone_id
}

# ------------------------------------------------------------
# CloudFront Distribution ID
#
# Wird benötigt für Cache Invalidations in der Pipeline
# und für die IAM Policy der GitHub Actions Role.
# ------------------------------------------------------------
output "distribution_id" {
  value = aws_cloudfront_distribution.this.id
}
