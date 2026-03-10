# ============================================================
# GitHub Actions IAM Role
#
# Diese Rolle wird von der GitHub Actions Pipeline verwendet,
# um:
# - Docker Images nach ECR zu pushen
# - auf den EKS Cluster zuzugreifen
# - CloudFront Cache Invalidations auszuführen
#
# WICHTIG:
# Diese Rolle existiert bereits in AWS und wird im nächsten
# Schritt in Terraform importiert.
# Diese Datei allein verändert noch nichts in AWS, solange
# kein terraform apply ausgeführt wird.
# ============================================================

# ------------------------------------------------------------
# IAM Role für GitHub Actions
#
# GitHub OIDC darf diese Rolle annehmen.
# Dadurch werden keine statischen AWS Access Keys benötigt.
# ------------------------------------------------------------
resource "aws_iam_role" "github_actions_eks_deploy_role" {
  name = "GitHubActionsEKSDeployRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::038217523163:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:mmorgen648/cloudy-with-a-chance-of-feedback:*"
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------
# AWS Managed Policy:
# ECR Push / Pull Rechte für die Pipeline
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "github_actions_ecr_power_user" {
  role       = aws_iam_role.github_actions_eks_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# ------------------------------------------------------------
# AWS Managed Policy:
# Basisrechte für EKS Cluster Zugriff
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "github_actions_eks_cluster_policy" {
  role       = aws_iam_role.github_actions_eks_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------
# AWS Managed Policy:
# Worker Node Policy
#
# Diese Policy war bereits manuell an der Rolle angehängt
# und wird hier bewusst 1:1 in Terraform übernommen.
# ------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "github_actions_eks_worker_node_policy" {
  role       = aws_iam_role.github_actions_eks_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# ------------------------------------------------------------
# Inline Policy:
# Erlaubt CloudFront Cache Invalidation
#
# Diese Berechtigung wird für die Pipeline benötigt,
# damit nach einem Frontend Deploy alte gecachte JS/HTML
# Dateien aus CloudFront entfernt werden.
# ------------------------------------------------------------
resource "aws_iam_role_policy" "github_actions_cloudfront_invalidation" {
  name = "CloudFrontInvalidation"
  role = aws_iam_role.github_actions_eks_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = "arn:aws:cloudfront::038217523163:distribution/EEFDFZ6ZWF6FL"
      }
    ]
  })
}