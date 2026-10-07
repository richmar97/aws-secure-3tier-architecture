# aws-secure-3tier-architecture
Highly available 3-tier enterprise architecture on AWS using Terraform: ALB, Auto Scaling, RDS Multi-AZ, and automated Secrets Manager credential rotation.

# Secure & Resilient 3-Tier Enterprise AWS Architecture with Terraform

In this project, I architected and deployed a highly available, multi-AZ 3-tier enterprise cloud infrastructure using Terraform. The architecture enforces zero-trust network tiering, automated secrets lifecycle management via AWS Secrets Manager, and compute autoscaling behind an Application Load Balancer.

---

## 🎯 Architecture Goals

* **Strict Network Isolation:** Separate public ingress, compute, and persistence tiers across multiple Availability Zones (`eu-central-1a` & `eu-central-1b`).
* **Zero Hardcoded Credentials:** Cryptographically random database credentials generated, stored, and managed securely with AWS Secrets Manager and KMS.
* **Security Group Chaining:** Compute resources only accept traffic originating from the ALB security group; the database tier exclusively allows ingress from compute security groups.
* **High Availability & Fault Tolerance:** Multi-AZ Amazon RDS PostgreSQL failover and Auto Scaling compute instances distributed across isolated subnets.

---

## 🏗️ 3-Tier Architectural Blueprint

```text
       Internet Traffic (Clients)
                   │
                   ▼ (Port 80/443)
  ┌─────────────────────────────────────────────────────────────┐
  │ TIER 1: Public Subnets (eu-central-1a & 1b)                 │
  │   └── Application Load Balancer (ALB)                       │
  └────────────────────────┬────────────────────────────────────┘
                           │ (Forward to Target Group)
  ┌────────────────────────▼────────────────────────────────────┐
  │ TIER 2: Private App Subnets (No Public IPs)                 │
  │   └── Auto Scaling Group (EC2 Nodes)                        │
  │         ├── Ingress: Strictly limited to ALB Security Group │
  │         └── IAM Role: Least-Privilege read from Secrets Mgr │
  └────────────────────────┬────────────────────────────────────┘
                           │ (PostgreSQL Port 5432)
  ┌────────────────────────▼────────────────────────────────────┐
  │ TIER 3: Isolated Database Subnets (No Internet Routing)     │
  │   └── Amazon RDS PostgreSQL (Multi-AZ Deployment)           │
  │         └── Ingress: Strictly limited to App Security Group │
  └─────────────────────────────────────────────────────────────┘
