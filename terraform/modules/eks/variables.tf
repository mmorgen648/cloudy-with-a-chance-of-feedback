# ============================================================
# EKS Module Variables
# Definiert Eingabewerte aus dem Root-Modul
# ============================================================

# Name des EKS Clusters
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

# VPC ID (vom Network Modul)
variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

# Public Subnet IDs für Worker Nodes
variable "public_subnet_ids" {
  description = "List of public subnet IDs for worker nodes"
  type        = list(string)
}

# AWS Region
variable "region" {
  description = "AWS region"
  type        = string
}

# Security Group ID für den EKS Control Plane (kommt aus modules/security-groups)
variable "cluster_security_group_id" {
  description = "Security group ID attached to the EKS control plane"
  type        = string
}