# ============================================================
# Remote Backend Configuration
# Verwendet bestehenden S3 Bucket + DynamoDB Locking
# ============================================================

terraform {
  backend "s3" {
    bucket         = "cloudy-feedback-tfstate-eu-central-1"
    key            = "network/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cloudy-feedback-terraform-locks"
    encrypt        = true
  }
}
