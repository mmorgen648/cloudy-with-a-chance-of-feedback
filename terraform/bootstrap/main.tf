#################################################
# main.tf
# Erstellt:
# 1) S3 Bucket für Terraform Remote State
# 2) DynamoDB Tabelle für State Locking
#################################################

##############################
# S3 Bucket für Terraform State
##############################

resource "aws_s3_bucket" "terraform_state" {
  bucket = "cloudy-feedback-tfstate-eu-central-1"

  tags = {
    Project = "CloudyWithAChanceOfFeedback"
    Purpose = "Terraform Remote State"
  }
}

##############################
# Versionierung aktivieren
##############################

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

##############################
# Verschlüsselung aktivieren
##############################

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

##############################
# DynamoDB Tabelle für Locking
##############################

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "cloudy-feedback-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = "CloudyWithAChanceOfFeedback"
    Purpose = "Terraform State Locking"
  }
}
