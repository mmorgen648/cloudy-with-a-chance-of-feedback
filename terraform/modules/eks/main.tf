# ============================================================
# EKS Module - Main
# Erstellt den EKS Control Plane (Cluster) + nötige IAM-Rolle
# ============================================================

# ------------------------------------------------------------
# IAM Role für den EKS Cluster (Control Plane)
# AWS benötigt diese Rolle, damit EKS intern AWS-Ressourcen nutzen darf.
# ------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# AWS-managed Policy: Basis-Rechte für EKS Control Plane
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# AWS-managed Policy: benötigt für bestimmte VPC-Resource Aktionen (Standard bei EKS)
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ------------------------------------------------------------
# EKS Cluster (Control Plane)
# Wichtig für "kein NAT":
# - endpoint_public_access = true
#   Damit der Zugriff auf die Kubernetes API auch ohne NAT möglich ist.
# ------------------------------------------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Control Plane wird in Subnets platziert (mind. 2 AZs)
    subnet_ids = var.public_subnet_ids

    # API Endpoint öffentlich erreichbar (ohne NAT-Requirement für Basic-Setup)
    endpoint_public_access  = true
    endpoint_private_access = false

    # Zusätzliche SG 
    security_group_ids = [var.cluster_security_group_id]
  }

  # Stellt sicher, dass Policies wirklich dran sind, bevor EKS erstellt wird
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller
  ]
}

# ============================================================
# OIDC Provider für EKS (IRSA Unterstützung)
# ------------------------------------------------------------
# Jeder EKS Cluster besitzt eine eigene OIDC URL.
# Damit Kubernetes ServiceAccounts IAM Rollen annehmen können
# (IRSA – IAM Roles for Service Accounts), muss dieser OIDC
# Provider einmal in IAM registriert werden.
#
# Wenn der Cluster zerstört und neu erstellt wird,
# bekommt er eine neue OIDC ID. Durch Terraform wird
# der passende Provider automatisch erzeugt.
# ============================================================

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {

  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint
  ]
}

# ============================================================
# IAM Role für EKS Worker Nodes (Managed Node Group)
# Diese Rolle erlaubt den EC2-Instanzen im Cluster,
# mit EKS, ECR und dem Netzwerk zu sprechen.
# ============================================================

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  # EC2 Instanzen dürfen diese Rolle übernehmen
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# ------------------------------------------------------------
# Notwendige AWS Managed Policies für Worker Nodes
# ------------------------------------------------------------

# Erlaubt Kommunikation mit dem EKS Control Plane
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Erlaubt Zugriff auf Container Images in ECR
resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Erlaubt Nutzung von CNI (Netzwerk im Cluster)
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ============================================================
# EKS Managed Node Group
# Erstellt die Worker Nodes (EC2 Instanzen)
# ============================================================

# --------------------------------------------------
# DOZENTENVORGABE (VERBINDLICH)
# --------------------------------------------------
# - Instance Type: t3.small
# - Genau 1 Node wenn aktiv
# - Keine High Availability
# - Keine zusätzlichen Node Groups
# - Keine Replica-Erhöhung ohne ausdrückliche Freigabe
#
# Kostenregel bleibt bestehen:
# - Bei Pause: desired_size = 0
# - Bei längerer Inaktivität: terraform destroy module.eks
# --------------------------------------------------

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  # Public Subnets laut Aufgabenstellung
  subnet_ids = var.public_subnet_ids

  # Skalierungsregeln laut Vorgabe
  scaling_config {
  # Während aktiver Entwicklung läuft genau ein Worker Node
  desired_size = 1
  min_size     = 0
  max_size     = 4
}

  # Instanztyp – ausreichend für Projekt
  instance_types = ["t3.small"]

  # Sicherstellen, dass IAM Policies existieren
  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_iam_role_policy_attachment.node_cni_policy
  ]
}

# ============================================================
# Ingress automatisch löschen vor EKS Destroy
#
# Der ALB wird vom Kubernetes Ingress Controller erstellt –
# nicht von Terraform. Damit Terraform die VPC sauber löschen
# kann, muss der ALB vorher aufgeräumt werden.
#
# Dieser null_resource führt beim terraform destroy automatisch
# kubectl delete ingress --all aus, bevor EKS gelöscht wird.
# Dadurch räumt der Ingress Controller den ALB selbst auf.
# ============================================================
resource "null_resource" "delete_ingress_before_destroy" {

  triggers = {
    cluster_name = aws_eks_cluster.this.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete ingress --all --ignore-not-found=true && sleep 30"
  }

  depends_on = [
    aws_eks_node_group.this
  ]
}
