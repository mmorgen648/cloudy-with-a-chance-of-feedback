# CloudyWithAChanceOfFeedback – Verbindliche Projektanforderungen

Quelle: Offizielle Abschlussprojekt-Anforderungen (CloudHelden Weiterbildung)

---

# 1. Infrastruktur (Terraform Pflicht)

## Allgemein

- Keine manuelle AWS Console Nutzung
- Alles über Terraform
- Remote State in S3 mit Versionierung
- State Locking via DynamoDB
- terraform.tfvars NICHT committen

## Netzwerk

- Eigene VPC
- Mindestens 2 Availability Zones
- Public + Private Subnets
- Internet Gateway
- KEIN NAT Gateway (außer Advanced-Variante)
- RDS immer in Private Subnets

## EKS

- Managed EKS Cluster
- Node Group:
  - desired = 1
  - min = 0
  - max = 4
  - Standard: Public Subnets
  - Demo: 2 Nodes
  - Pause: 0 Nodes
- AWS Load Balancer Controller verwenden
- Horizontal Pod Autoscaler ODER Cluster Autoscaler

## Datenbank

- RDS PostgreSQL
- db.t3.micro
- Private Subnet
- Bei Pause: stoppen oder Snapshot + löschen

## Auth

- AWS Cognito User Pool
- Rollen (Admin / User)
- JWT Validierung im Backend

## Registry

- ECR oder DockerHub
- Kein :latest Tag
- Commit SHA als Tag

## TLS / DNS

- ACM Zertifikat:
  - ALB: eigene Region
  - CloudFront: zwingend us-east-1
- CloudFront vor ALB
- Route 53 DNS Eintrag

---

# 2. Kubernetes Pflicht-Ressourcen

- Deployment (Frontend + Backend)
- Service (ClusterIP)
- Ingress (ALB Ingress)
- ConfigMap
- Secret (keine Secrets im Code!)
- HorizontalPodAutoscaler
- Liveness Probe
- Readiness Probe
- Resource Limits & Requests

Empfohlene Ressourcen:

- Frontend: 2 Replicas | 256Mi | 0.25 CPU
- Backend: 2 Replicas | 512Mi | 0.5 CPU

---

# 3. Anwendung

Backend:

- Spring Boot oder Node.js
- REST API
- RDS Anbindung
- Cognito JWT Validierung
- AWS ML Service Integration

Frontend:

- HTML/CSS/Bootstrap
- Öffentlicher Bereich
- Geschützter Bereich mit Cognito Login
- Responsive

---

# 4. CI/CD (GitHub Actions)

Pipeline bei Push auf main:

1. Test (min. 5 Unit Tests)
2. Build (Docker Image)
3. Push (ECR, Tag = Commit SHA)
4. Deploy (kubectl apply)
5. rollout status prüfen (timeout 120s)

Deploy nur wenn Test + Build erfolgreich.

---

# 5. Kostenregeln

- EKS Node Group bei Pause auf 0
- RDS stoppen oder löschen
- terraform destroy wenn nicht aktiv
- Budget Alert $15

---

# 6. Verbote

- Keine Credentials in Git
- Kein :latest Tag
- Kein NAT Gateway (Standard)
- Keine große DB (nur db.t3.micro)
- Kein Overengineering
- Keine sensiblen Daten in terraform.tfvars
