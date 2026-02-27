# ============================================================
# Network Module
# Erstellt VPC, Subnets, Internet Gateway und Routing
# ============================================================

# ------------------------------------------------------------
# VPC
# Hauptnetzwerk für das gesamte Projekt
# ------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name    = "cloudy-feedback-vpc"
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ------------------------------------------------------------
# Public Subnets (für Load Balancer etc.)
# ------------------------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = {
    Name    = "cloudy-public-subnet-${count.index}"
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ------------------------------------------------------------
# Private Subnets (für EKS Nodes / RDS)
# ------------------------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}${count.index == 0 ? "a" : "b"}"

  tags = {
    Name    = "cloudy-private-subnet-${count.index}"
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ------------------------------------------------------------
# Internet Gateway
# Ermöglicht Internetzugang für Public Subnets
# ------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "cloudy-igw"
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# ------------------------------------------------------------
# Public Route Table
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name    = "cloudy-public-rt"
    Project = "CloudyWithAChanceOfFeedback"
  }
}

# Route ins Internet
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Route Table Association für Public Subnets
resource "aws_route_table_association" "public_assoc" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
