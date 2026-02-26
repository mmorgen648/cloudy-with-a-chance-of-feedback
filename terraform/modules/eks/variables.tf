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

# Private Subnet IDs für Worker Nodes
variable "private_subnet_ids" {
  description = "List of private subnet IDs for worker nodes"
  type        = list(string)
}

# AWS Region
variable "region" {
  description = "AWS region"
  type        = string
}