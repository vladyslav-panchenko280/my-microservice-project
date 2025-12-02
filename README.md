# Enterprise Suite Infrastructure

A production-ready, multi-environment infrastructure platform for deploying containerized applications on AWS EKS with complete CI/CD, GitOps, and monitoring capabilities.

---

## Table of Contents

- [Description](#description)
- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Accessing Applications](#accessing-applications)
- [Managing Infrastructure](#managing-infrastructure)
- [Managing Kubernetes](#managing-kubernetes)
- [Managing CI/CD Services](#managing-cicd-services)
- [Managing Databases](#managing-databases)
- [Managing Monitoring](#managing-monitoring)
- [Adding New Services](#adding-new-services)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

---

## Description

This infrastructure platform provides a complete, enterprise-grade solution for deploying and managing containerized applications across development, staging, and production environments. Built on AWS and Kubernetes, it implements modern DevOps practices including Infrastructure as Code (IaC), GitOps, and comprehensive observability.

**Key Features:**
- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **Infrastructure as Code**: All infrastructure managed via Terraform
- **Kubernetes Orchestration**: AWS EKS for container management
- **Automated CI/CD**: Jenkins pipelines with environment-specific builds
- **GitOps Deployment**: Argo CD for declarative, automated deployments
- **Full Observability**: Prometheus + Grafana monitoring stack
- **Database Management**: Aurora PostgreSQL / RDS with automated backups
- **Security Best Practices**: IRSA, secrets management, encrypted state
- **High Availability**: Multi-AZ deployments, auto-scaling, pod anti-affinity

---

## Architecture Overview

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VPC (per environment)                   │  │
│  │  ┌─────────────────────┐  ┌──────────────────────────┐   │  │
│  │  │  Public Subnets     │  │   Private Subnets        │   │  │
│  │  │  - NAT Gateways     │  │   - EKS Worker Nodes     │   │  │
│  │  │  - Load Balancers   │  │   - Application Pods     │   │  │
│  │  └─────────────────────┘  │   - RDS/Aurora Instances │   │  │
│  │                            └──────────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────┐  ┌─────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   ECR   │  │   EKS   │  │  RDS/Aurora  │  │  S3 Backend  │ │
│  └─────────┘  └─────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Kubernetes Services Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                       EKS Cluster                              │
│                                                                 │
│  Namespace: jenkins                Namespace: argocd          │
│  ┌──────────────────┐              ┌──────────────────┐       │
│  │  Jenkins Master  │              │  Argo CD Server  │       │
│  │  - CI/CD Jobs    │─────────────▶│  - GitOps Sync   │       │
│  │  - Docker Build  │              │  - Auto Deploy   │       │
│  └──────────────────┘              └──────────────────┘       │
│                                                                 │
│  Namespace: monitoring             Namespace: django-{env}    │
│  ┌──────────────────┐              ┌──────────────────┐       │
│  │   Prometheus     │◀─────────────│   Django App     │       │
│  │   + Grafana      │   metrics    │   + Nginx        │       │
│  │   + Alertmanager │              │   + Worker Pods  │       │
│  └──────────────────┘              └──────────────────┘       │
└────────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Flow

```
Developer Push         Jenkins Build          Argo CD Deploy
     │                      │                       │
     ▼                      ▼                       ▼
┌─────────┐  trigger  ┌──────────┐  update  ┌───────────┐
│   Git   │──────────▶│ Jenkins  │─────────▶│  Git Repo │
│  Commit │           │ Pipeline │          │  (values) │
└─────────┘           └──────────┘          └───────────┘
                           │                       │
                      ┌────┴────┐            ┌─────┴──────┐
                      ▼         ▼            ▼            ▼
                  ┌─────┐  ┌────────┐  ┌─────────┐  ┌──────┐
                  │ ECR │  │ Docker │  │ Argo CD │  │ EKS  │
                  │Image│  │ Build  │  │  Sync   │  │ Pods │
                  └─────┘  └────────┘  └─────────┘  └──────┘
```

---

## Project Structure

```
enterprise-suite-infrastructure/
│
├── infrastructure/                    # Terraform Infrastructure as Code
│   ├── environments/                  # Environment-specific configurations
│   │   ├── dev/
│   │   │   ├── backend.hcl           # S3 backend config
│   │   │   └── terraform.tfvars      # Dev variables
│   │   ├── stage/
│   │   │   ├── backend.hcl
│   │   │   └── terraform.tfvars      # Staging variables
│   │   └── prod/
│   │       ├── backend.hcl
│   │       └── terraform.tfvars      # Production variables
│   │
│   ├── modules/                       # Reusable Terraform modules
│   │   ├── vpc/                      # VPC with public/private subnets
│   │   │   ├── vpc.tf
│   │   │   ├── routes.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── ecr/                      # Container registry
│   │   │   ├── ecr.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── eks/                      # Kubernetes cluster
│   │   │   ├── eks.tf
│   │   │   ├── node.tf
│   │   │   ├── aws_ebs_csi_driver.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── rds/                      # Database (Aurora/RDS)
│   │   │   ├── shared.tf
│   │   │   ├── rds.tf               # Standard RDS
│   │   │   ├── aurora.tf            # Aurora cluster
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── jenkins/                  # Jenkins CI/CD
│   │   │   ├── jenkins.tf
│   │   │   ├── providers.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── argocd/                   # GitOps continuous delivery
│   │   │   ├── argocd.tf
│   │   │   ├── providers.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   ├── prometheus/               # Monitoring (Prometheus)
│   │   │   ├── prometheus.tf
│   │   │   ├── providers.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   │
│   │   └── grafana/                  # Visualization (Grafana)
│   │       ├── grafana.tf
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── main.tf                       # Root module orchestration
│   ├── variables.tf                  # Root variables
│   ├── outputs.tf                    # Root outputs
│   ├── providers.tf                  # Provider configurations
│   └── backend.tf                    # S3 backend configuration
│
├── charts/                           # Helm Charts
│   ├── jenkins/
│   │   ├── Chart.yaml               # Jenkins Helm chart metadata
│   │   ├── values.yaml              # Base configuration
│   │   ├── values-dev.yaml          # Dev overrides
│   │   ├── values-stage.yaml        # Staging overrides
│   │   └── values-prod.yaml         # Production overrides
│   │
│   ├── argocd/
│   │   ├── Chart.yaml               # Argo CD Helm chart metadata
│   │   ├── values.yaml              # Base configuration
│   │   ├── values-dev.yaml          # Dev overrides
│   │   ├── values-stage.yaml        # Staging overrides
│   │   └── values-prod.yaml         # Production overrides
│   │
│   ├── prometheus/
│   │   ├── Chart.yaml               # Prometheus stack metadata
│   │   ├── values.yaml              # Base configuration
│   │   ├── values-dev.yaml          # Dev overrides
│   │   ├── values-stage.yaml        # Staging overrides
│   │   └── values-prod.yaml         # Production overrides
│   │
│   └── grafana/
│       ├── Chart.yaml               # Grafana metadata
│       ├── values.yaml              # Base configuration
│       ├── values-dev.yaml          # Dev overrides
│       ├── values-stage.yaml        # Staging overrides
│       └── values-prod.yaml         # Production overrides
│
├── services/                         # Application services
│   └── django-app/
│       ├── django_app/              # Django application code
│       │   ├── Dev.Dockerfile       # Development build
│       │   ├── Stage.Dockerfile     # Staging build (optimized)
│       │   ├── Prod.Dockerfile      # Production build (multi-stage)
│       │   ├── requirements.txt
│       │   ├── manage.py
│       │   └── settings.py
│       │
│       ├── nginx/                   # Nginx reverse proxy
│       │   ├── nginx.conf
│       │   └── Dockerfile
│       │
│       ├── k8s/                     # Kubernetes manifests
│       │   ├── values-dev.yaml
│       │   ├── values-stage.yaml
│       │   └── values-prod.yaml
│       │
│       ├── Jenkinsfile              # CI/CD pipeline definition
│       └── docker-compose.yml       # Local development
│
└── scripts/                          # Automation scripts
    ├── terraform-apply.sh           # Apply infrastructure
    ├── build-and-push.sh            # Build and push Docker images
    ├── deploy.sh                    # Deploy via Helm
    └── setup-environment.sh         # Complete environment setup
```

---

## Repository Structure

This infrastructure project uses a **two-repository** approach:

### Infrastructure Repository
**Repository**: `vladyslav-panchenko280/enterprise-suite-infrastructure`

Contains:
- Terraform infrastructure code
- Helm charts for platform services (Jenkins, Argo CD, Prometheus, Grafana)
- Automation scripts
- Environment configurations

### Application Repository
**Repository**: `vladyslav-panchenko280/django-app`

Contains:
- Application source code (Django)
- Environment-specific Dockerfiles
- Jenkinsfile for CI/CD pipeline
- Kubernetes Helm values for deployments

**Branch Strategy**:
- `dev` branch → Dev environment → `Dev.Dockerfile`
- `stage` branch → Staging environment → `Stage.Dockerfile`
- `main` branch → Production environment → `Prod.Dockerfile`

---

## Prerequisites

Before starting, ensure you have the following installed and configured:

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [AWS CLI](https://aws.amazon.com/cli/) | Latest | AWS resource management |
| [Terraform](https://www.terraform.io/) | ≥ 1.0 | Infrastructure as Code |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | ≥ 1.24 | Kubernetes management |
| [Helm](https://helm.sh/) | ≥ 3.0 | Kubernetes package manager |
| [Docker](https://www.docker.com/) | Latest | Container builds |
| [Git](https://git-scm.com/) | Latest | Version control |

### AWS Requirements

- **AWS Account** with administrative access
- **AWS CLI** configured with valid credentials:
  ```bash
  aws configure
  # Enter: AWS Access Key ID, Secret Access Key, Region (us-east-1)
  ```
- **AWS Account ID** (find with: `aws sts get-caller-identity --query Account --output text`)

### GitHub Requirements

- GitHub account with repository access
- Personal Access Token (PAT) with `repo` scope
  - Generate at: https://github.com/settings/tokens
  - Scopes needed: `repo` (full control of private repositories)

---

## Quick Start

### Step 1: Create S3 Backend for Terraform State

**One-time setup** - Create an S3 bucket to store Terraform state:

```bash
# Replace with your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket
aws s3api create-bucket \
  --bucket es-terraform-state-${AWS_ACCOUNT_ID} \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket es-terraform-state-${AWS_ACCOUNT_ID} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket es-terraform-state-${AWS_ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "✅ Terraform state bucket created: es-terraform-state-${AWS_ACCOUNT_ID}"
```

### Step 2: Configure Environment Variables

Edit environment-specific configuration file:

```bash
# For development environment
vim infrastructure/environments/dev/terraform.tfvars
```

**Update the following values:**

```hcl
# AWS Configuration
aws_account_id = "YOUR_AWS_ACCOUNT_ID"

# GitHub Credentials for Jenkins
jenkins_github_username = "your-github-username"
jenkins_github_token    = "ghp_your_personal_access_token_here"

# Database Configuration
db_password = "ChangeThisSecurePassword123!"

# Grafana Configuration
grafana_admin_password = "secure-grafana-password"

# Update backend bucket in backend.hcl
# infrastructure/environments/dev/backend.hcl
bucket = "es-terraform-state-YOUR_AWS_ACCOUNT_ID"
```

### Step 3: Deploy Infrastructure

Deploy the complete infrastructure stack:

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
terraform init -backend-config=environments/dev/backend.hcl

# Review planned changes
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars

# Or use the automation script
cd ..
./scripts/terraform-apply.sh dev
```

**What gets created:**
- ✅ VPC with public/private subnets across 2 availability zones
- ✅ EKS cluster with managed node groups
- ✅ ECR repository for Docker images
- ✅ RDS PostgreSQL database (or Aurora cluster)
- ✅ Jenkins CI/CD server with IRSA permissions
- ✅ Argo CD GitOps controller
- ✅ Prometheus + Grafana monitoring stack
- ✅ All necessary IAM roles, security groups, and networking

**Deployment time**: ~20-30 minutes

### Step 4: Configure kubectl Access

Connect kubectl to your new EKS cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-cluster-dev

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

### Step 5: Retrieve Service Credentials

```bash
# Jenkins admin password
kubectl get secret -n jenkins jenkins-admin-password \
  -o jsonpath='{.data.password}' | base64 -d
echo

# Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo

# Grafana credentials (from terraform.tfvars)
# Username: admin
# Password: dev-admin (or as configured)
```

### Step 6: Access Services

```bash
# Jenkins (CI/CD)
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# Open: http://localhost:8080

# Argo CD (GitOps)
kubectl port-forward -n argocd svc/argocd-server 8081:443
# Open: https://localhost:8081

# Grafana (Monitoring)
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open: http://localhost:3000

# Prometheus (Metrics)
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open: http://localhost:9090
```

---

## Environment Configuration

### Environment Comparison

| Feature | Development | Staging | Production |
|---------|-------------|---------|------------|
| **Infrastructure** ||||
| Availability Zones | 2 | 3 | 3 |
| NAT Gateways | 1 (cost-optimized) | 3 (per AZ) | 3 (per AZ) |
| EKS Node Type | t4g.small | t3.large | t3.xlarge |
| EKS Node Count | 1-2 | 2-5 | 3-10 |
| **Database** ||||
| Database Type | RDS | Aurora | Aurora |
| Instance Class | db.t3.micro | db.r6g.large | db.r6g.xlarge |
| Multi-AZ | No | Yes | Yes |
| Backup Retention | 3 days | 7 days | 30 days |
| Read Replicas | 0 | 1 | 2 |
| **Monitoring** ||||
| Prometheus Retention | 7 days | 15 days | 30 days |
| Prometheus Storage | 20GB | 40GB | 100GB |
| Prometheus Replicas | 1 | 2 | 2 |
| Grafana Replicas | 1 | 2 | 3 |
| Alerting | Basic | Enhanced | Full |
| **Security** ||||
| Secrets Management | tfvars | tfvars | AWS Secrets Manager |
| Pod Security | Standard | Standard | Restricted |
| Network Policies | Basic | Enhanced | Strict |

### Configuration Files

Each environment has dedicated configuration:

```bash
infrastructure/environments/
├── dev/
│   ├── backend.hcl              # S3 backend: es-terraform-state-dev
│   └── terraform.tfvars         # Dev-specific variables
├── stage/
│   ├── backend.hcl              # S3 backend: es-terraform-state-staging
│   └── terraform.tfvars         # Staging-specific variables
└── prod/
    ├── backend.hcl              # S3 backend: es-terraform-state-prod
    └── terraform.tfvars         # Production-specific variables
```

### Switching Between Environments

```bash
cd infrastructure

# Switch to staging
terraform init -backend-config=environments/stage/backend.hcl -reconfigure
terraform apply -var-file=environments/stage/terraform.tfvars

# Switch to production
terraform init -backend-config=environments/prod/backend.hcl -reconfigure
terraform apply -var-file=environments/prod/terraform.tfvars
```

---

## Accessing Applications

### Quick Access Summary

| Service | Port-Forward Command | URL | Default Credentials |
|---------|---------------------|-----|-------------------|
| **Jenkins** | `kubectl port-forward -n jenkins svc/jenkins 8080:8080` | http://localhost:8080 | admin / (from k8s secret) |
| **Argo CD** | `kubectl port-forward -n argocd svc/argocd-server 8081:443` | https://localhost:8081 | admin / (from k8s secret) |
| **Grafana** | `kubectl port-forward -n monitoring svc/grafana 3000:80` | http://localhost:3000 | admin / dev-admin |
| **Prometheus** | `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090` | http://localhost:9090 | No auth |
| **Django App** | `kubectl port-forward -n django-dev svc/django-app 8000:8000` | http://localhost:8000 | - |

### Accessing via LoadBalancer (Staging/Production)

Services in staging and production are exposed via AWS LoadBalancers:

```bash
# Get LoadBalancer URLs
kubectl get svc --all-namespaces -o wide | grep LoadBalancer

# Get specific service URL
kubectl get svc -n django-stage django-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Example output:
# a1234567890abcdef-1234567890.us-east-1.elb.amazonaws.com
```

### Retrieving Service Credentials

#### Jenkins Password

```bash
kubectl get secret -n jenkins jenkins-admin-password \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

#### Argo CD Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

#### Grafana Password

```bash
# Password is set in terraform.tfvars
# Development: dev-admin
# Staging: stage-admin-secure
# Production: Use AWS Secrets Manager

# To reset password:
kubectl exec -it -n monitoring deployment/grafana -- \
  grafana-cli admin reset-admin-password newpassword
```

#### Database Credentials

```bash
# Database credentials are stored in Kubernetes secrets
kubectl get secret django-db-credentials -n django-dev -o yaml

# Get specific credential
kubectl get secret django-db-credentials -n django-dev \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d && echo
```

---

## Managing Infrastructure

### Viewing Infrastructure State

```bash
cd infrastructure

# List all resources
terraform state list

# Show specific resource
terraform state show module.eks.aws_eks_cluster.main

# View outputs
terraform output

# View specific output
terraform output db_host
terraform output eks_cluster_endpoint
```

### Updating Infrastructure

```bash
# Make changes to .tf files or terraform.tfvars

# Review changes
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars

# Apply specific module
terraform apply -target=module.rds -var-file=environments/dev/terraform.tfvars
```

### Scaling Infrastructure

#### Scale EKS Node Groups

```bash
# Edit terraform.tfvars
desired_size = 3  # Change from 2 to 3
min_size     = 2
max_size     = 5

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars
```

#### Upgrade EKS Node Instance Type

```bash
# Edit terraform.tfvars
instance_type = "t3.large"  # Upgrade from t4g.small

# Apply changes (will replace nodes)
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Destroying Infrastructure

```bash
# Destroy specific environment
cd infrastructure
terraform init -backend-config=environments/dev/backend.hcl -reconfigure
terraform destroy -var-file=environments/dev/terraform.tfvars

# Or use the cleanup script
./scripts/cleanup-environment.sh dev
```

### Infrastructure Backup and Recovery

#### Backup Terraform State

```bash
# Download current state
aws s3 cp s3://es-terraform-state-${AWS_ACCOUNT_ID}/dev/terraform.tfstate \
  ./backups/terraform.tfstate.$(date +%Y%m%d-%H%M%S)
```

#### Import Existing Resources

```bash
# Import existing AWS resource into Terraform
terraform import module.eks.aws_eks_cluster.main eks-cluster-dev

# Import RDS instance
terraform import module.rds.aws_db_instance.standard myapp-db-dev
```

---

## Managing Kubernetes

### Cluster Information

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes -o wide

# Get all resources across namespaces
kubectl get all --all-namespaces

# Describe node
kubectl describe node <node-name>
```

### Managing Namespaces

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace my-app

# Delete namespace (deletes all resources inside)
kubectl delete namespace my-app
```

### Managing Pods

```bash
# List pods in specific namespace
kubectl get pods -n django-dev

# Get detailed pod information
kubectl describe pod <pod-name> -n django-dev

# View pod logs
kubectl logs -f <pod-name> -n django-dev

# View logs from specific container
kubectl logs -f <pod-name> -c django-app -n django-dev

# View previous container logs (for crashed pods)
kubectl logs <pod-name> -n django-dev --previous

# Execute command in pod
kubectl exec -it <pod-name> -n django-dev -- /bin/bash

# Copy files to/from pod
kubectl cp <local-file> <pod-name>:/path/in/pod -n django-dev
kubectl cp <pod-name>:/path/in/pod <local-file> -n django-dev
```

### Scaling Applications

```bash
# Scale deployment
kubectl scale deployment django-app -n django-dev --replicas=3

# Autoscaling (HPA)
kubectl autoscale deployment django-app -n django-dev \
  --min=2 --max=10 --cpu-percent=80

# View HPA status
kubectl get hpa -n django-dev
```

### Rolling Updates and Rollbacks

```bash
# View deployment history
kubectl rollout history deployment/django-app -n django-dev

# Update deployment image
kubectl set image deployment/django-app \
  django-app=625041985844.dkr.ecr.us-east-1.amazonaws.com/es-ecr-dev:new-tag \
  -n django-dev

# Monitor rollout status
kubectl rollout status deployment/django-app -n django-dev

# Rollback to previous version
kubectl rollout undo deployment/django-app -n django-dev

# Rollback to specific revision
kubectl rollout undo deployment/django-app -n django-dev --to-revision=2
```

### Managing ConfigMaps and Secrets

```bash
# Create secret from literal
kubectl create secret generic my-secret \
  --from-literal=password=mysecretpassword \
  -n django-dev

# Create secret from file
kubectl create secret generic my-secret \
  --from-file=ssh-privatekey=~/.ssh/id_rsa \
  -n django-dev

# View secret
kubectl get secret my-secret -n django-dev -o yaml

# Create ConfigMap
kubectl create configmap my-config \
  --from-literal=app.name=myapp \
  --from-literal=app.env=development \
  -n django-dev

# View ConfigMap
kubectl get configmap my-config -n django-dev -o yaml
```

### Resource Management

```bash
# View resource usage
kubectl top nodes
kubectl top pods -n django-dev

# Set resource limits
kubectl set resources deployment django-app -n django-dev \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=250m,memory=256Mi

# View resource quotas
kubectl get resourcequota -n django-dev
kubectl describe resourcequota -n django-dev
```

### Network and Services

```bash
# List services
kubectl get svc -n django-dev

# Describe service
kubectl describe svc django-app -n django-dev

# Get service endpoints
kubectl get endpoints django-app -n django-dev

# Test service connectivity
kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -- /bin/bash
# Inside the pod:
curl http://django-app.django-dev.svc.cluster.local:8000
```

---

## Managing CI/CD Services

### Jenkins CI/CD

#### Accessing Jenkins

```bash
# Get admin password
kubectl get secret -n jenkins jenkins-admin-password \
  -o jsonpath='{.data.password}' | base64 -d && echo

# Port forward
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# Open http://localhost:8080
# Login: admin / <password from above>
```

#### Managing Jenkins Jobs

**Pipeline Flow:**
1. Developer pushes code to Git branch (`dev`, `stage`, or `main`)
2. Jenkins detects branch and determines environment
3. Builds Docker image using environment-specific Dockerfile
4. Pushes image to ECR
5. Updates Helm values file in Git with new image tag
6. Helm deploys updated application to Kubernetes

**Environment Detection:**
- `dev` branch → `Dev.Dockerfile` → `django-dev` image → dev namespace
- `stage` branch → `Stage.Dockerfile` → `django-stage` image → stage namespace
- `main` branch → `Prod.Dockerfile` → `django-prod` image → prod namespace

#### Configuring Jenkins Jobs

Edit Helm values to add/modify Jenkins jobs:

```bash
# Edit values file
vim charts/jenkins/values-dev.yaml
```

```yaml
jenkins:
  controller:
    jobs:
      django-app-dev: |
        <?xml version='1.0' encoding='UTF-8'?>
        <flow-definition plugin="workflow-job@2.40">
          <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
            <scm class="hudson.plugins.git.GitSCM">
              <userRemoteConfigs>
                <hudson.plugins.git.UserRemoteConfig>
                  <url>https://github.com/vladyslav-panchenko280/django-app.git</url>
                </hudson.plugins.git.UserRemoteConfig>
              </userRemoteConfigs>
              <branches>
                <hudson.plugins.git.BranchSpec>
                  <name>*/dev</name>
                </hudson.plugins.git.BranchSpec>
              </branches>
            </scm>
            <scriptPath>Jenkinsfile</scriptPath>
          </definition>
        </flow-definition>
```

#### Scaling Jenkins

```bash
# Edit resources in values file
vim charts/jenkins/values-prod.yaml
```

```yaml
jenkins:
  controller:
    resources:
      requests:
        cpu: "2000m"
        memory: "4Gi"
      limits:
        cpu: "4000m"
        memory: "8Gi"

    # Add executors for parallel builds
    numExecutors: 5
```

Apply changes:

```bash
cd infrastructure
terraform apply -var-file=environments/prod/terraform.tfvars
```

#### Troubleshooting Jenkins

```bash
# View Jenkins logs
kubectl logs -n jenkins -l app.kubernetes.io/name=jenkins -f

# Check Jenkins pod status
kubectl get pods -n jenkins
kubectl describe pod <jenkins-pod> -n jenkins

# Restart Jenkins
kubectl rollout restart deployment/jenkins -n jenkins

# Access Jenkins shell
kubectl exec -it -n jenkins <jenkins-pod> -- /bin/bash
```

### Argo CD GitOps

#### Accessing Argo CD

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward
kubectl port-forward -n argocd svc/argocd-server 8081:443

# Open https://localhost:8081
# Login: admin / <password from above>
```

#### Argo CD Application Management

```bash
# List applications
kubectl get applications -n argocd

# Get application status
kubectl get application django-app-dev -n argocd -o wide

# Describe application
kubectl describe application django-app-dev -n argocd

# Manually sync application
kubectl patch application django-app-dev -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

#### Configuring Argo CD Applications

Argo CD applications are configured via Helm values:

```yaml
# charts/argocd/templates/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-app-{{ .Values.environment }}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vladyslav-panchenko280/django-app.git
    targetRevision: {{ .Values.environment }}
    path: charts/django-app
    helm:
      valueFiles:
        - values-{{ .Values.environment }}.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: django-{{ .Values.environment }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

#### Scaling Argo CD

```bash
# Edit Argo CD server replicas
vim charts/argocd/values-prod.yaml
```

```yaml
argo-cd:
  server:
    replicas: 3
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi

  repoServer:
    replicas: 2
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
```

#### Troubleshooting Argo CD

```bash
# View Argo CD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server -f

# View application controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller -f

# Check sync status
kubectl get applications -n argocd

# Force sync
argocd app sync django-app-dev

# View application details
argocd app get django-app-dev
```

---

## Managing Databases

### Database Configuration Overview

The RDS module supports both **Standard RDS** and **Aurora PostgreSQL** with environment-specific configurations.

#### Database Comparison

| Feature | RDS (Dev) | Aurora (Staging) | Aurora (Production) |
|---------|-----------|------------------|---------------------|
| Engine | PostgreSQL | Aurora PostgreSQL | Aurora PostgreSQL |
| Instance Class | db.t3.micro | db.r6g.large | db.r6g.xlarge |
| Multi-AZ | No | Yes | Yes |
| Read Replicas | 0 | 1 | 2 |
| Storage | 20GB | 50GB (auto-scaling) | 100GB (auto-scaling) |
| Backup Retention | 3 days | 7 days | 30 days |
| Max Connections | 100 | 300 | 1000 |
| Work Memory | 4MB (4096KB) | 8MB (8192KB) | 32MB (32768KB) |

### Connecting to Database

#### Get Database Endpoint

```bash
# Via Terraform output
cd infrastructure
terraform output db_host

# Via Kubernetes secret
kubectl get secret django-db-credentials -n django-dev \
  -o jsonpath='{.data.DB_HOST}' | base64 -d && echo
```

#### Connect via psql

```bash
# Get credentials
DB_HOST=$(kubectl get secret django-db-credentials -n django-dev -o jsonpath='{.data.DB_HOST}' | base64 -d)
DB_USER=$(kubectl get secret django-db-credentials -n django-dev -o jsonpath='{.data.DB_USER}' | base64 -d)
DB_PASS=$(kubectl get secret django-db-credentials -n django-dev -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)
DB_NAME=$(kubectl get secret django-db-credentials -n django-dev -o jsonpath='{.data.DB_NAME}' | base64 -d)

# Connect
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
# Enter password when prompted
```

#### Connect from Application Pod

```bash
# Exec into Django pod
kubectl exec -it -n django-dev <pod-name> -- /bin/bash

# Inside pod, use Django shell
python manage.py dbshell

# Or use psql with environment variables
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

### Database Migrations

```bash
# Run Django migrations from pod
kubectl exec -it -n django-dev <pod-name> -- python manage.py migrate

# Check migration status
kubectl exec -it -n django-dev <pod-name> -- python manage.py showmigrations

# Create new migration
kubectl exec -it -n django-dev <pod-name> -- python manage.py makemigrations

# Run specific migration
kubectl exec -it -n django-dev <pod-name> -- \
  python manage.py migrate myapp 0002_auto_20250101_1200
```

### Scaling Databases

#### Change Database Instance Class

```bash
# Edit terraform.tfvars
vim infrastructure/environments/prod/terraform.tfvars
```

```hcl
# Upgrade from db.r6g.large to db.r6g.xlarge
db_instance_class = "db.r6g.xlarge"
```

```bash
# Apply changes (will cause downtime for RDS, minimal for Aurora)
cd infrastructure
terraform apply -var-file=environments/prod/terraform.tfvars
```

#### Add Aurora Read Replicas

```bash
# Edit terraform.tfvars
vim infrastructure/environments/prod/terraform.tfvars
```

```hcl
# Increase read replicas from 2 to 3
db_aurora_instance_count = 4  # 1 writer + 3 readers
```

```bash
# Apply changes (no downtime)
cd infrastructure
terraform apply -var-file=environments/prod/terraform.tfvars
```

#### Adjust Database Parameters

```bash
# Edit terraform.tfvars
vim infrastructure/environments/prod/terraform.tfvars
```

```hcl
db_parameters = {
  max_connections = 2000      # Increase from 1000
  log_statement   = "mod"
  work_mem        = "65536"   # 64MB in KB
}
```

```bash
# Apply changes (requires database restart)
cd infrastructure
terraform apply -var-file=environments/prod/terraform.tfvars
```

### Switching Database Types

#### Switch from RDS to Aurora

```bash
# Edit terraform.tfvars
vim infrastructure/environments/stage/terraform.tfvars
```

```hcl
# Before (Standard RDS)
db_use_aurora = false
db_instance_class = "db.t3.small"
db_allocated_storage = 20

# After (Aurora)
db_use_aurora = true
db_aurora_instance_count = 2
db_instance_class = "db.r6g.large"
# allocated_storage is ignored for Aurora
```

```bash
# 1. Backup old database
pg_dump -h <old-rds-host> -U postgres myapp > backup.sql

# 2. Apply Terraform to create Aurora
terraform apply -var-file=environments/stage/terraform.tfvars

# 3. Restore to new Aurora cluster
psql -h <new-aurora-host> -U postgres myapp < backup.sql
```

### Database Backup and Restore

#### Automated Backups

AWS RDS/Aurora automatically creates daily backups based on retention period.

```bash
# View available backups (via AWS CLI)
aws rds describe-db-snapshots \
  --db-instance-identifier myapp-db-dev

# For Aurora
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier myapp-db-prod
```

#### Manual Snapshot

```bash
# Create snapshot for RDS
aws rds create-db-snapshot \
  --db-instance-identifier myapp-db-dev \
  --db-snapshot-identifier myapp-db-dev-manual-$(date +%Y%m%d)

# Create snapshot for Aurora
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier myapp-db-prod \
  --db-cluster-snapshot-identifier myapp-db-prod-manual-$(date +%Y%m%d)
```

#### Restore from Snapshot

```bash
# Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier myapp-db-dev-restored \
  --db-snapshot-identifier myapp-db-dev-manual-20250101

# Restore Aurora from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier myapp-db-prod-restored \
  --snapshot-identifier myapp-db-prod-manual-20250101 \
  --engine aurora-postgresql
```

#### Manual Backup (pg_dump)

```bash
# Full database backup
pg_dump -h <db-host> -U postgres -Fc myapp > myapp_backup_$(date +%Y%m%d).dump

# Schema only
pg_dump -h <db-host> -U postgres -s myapp > schema.sql

# Data only
pg_dump -h <db-host> -U postgres -a myapp > data.sql

# Specific table
pg_dump -h <db-host> -U postgres -t my_table myapp > my_table.sql
```

#### Restore from pg_dump

```bash
# Restore full backup
pg_restore -h <db-host> -U postgres -d myapp myapp_backup_20250101.dump

# Restore SQL file
psql -h <db-host> -U postgres -d myapp < backup.sql
```

### Database Monitoring

```bash
# View RDS metrics via AWS CLI
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-db-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average

# Check connection count from database
psql -h <db-host> -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# View slow queries
psql -h <db-host> -U postgres -c "
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"
```

### Database Troubleshooting

```bash
# Check database connectivity
kubectl run tmp-shell --rm -i --tty --image postgres:15 -- /bin/bash
psql -h <db-host> -U postgres -d myapp

# View database logs (RDS)
aws rds download-db-log-file-portion \
  --db-instance-identifier myapp-db-dev \
  --log-file-name error/postgresql.log.2025-01-01-12

# Check database parameters
aws rds describe-db-parameters \
  --db-parameter-group-name myapp-db-dev-rds-params

# Verify secret injection in pod
kubectl exec -it -n django-dev <pod-name> -- env | grep DB_
```

---

## Managing Monitoring

### Prometheus Monitoring

#### Accessing Prometheus

```bash
# Port forward
kubectl port-forward -n monitoring \
  svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open http://localhost:9090
```

#### Key Prometheus Queries

```promql
# Node CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod, namespace)

# Pod memory usage
sum(container_memory_working_set_bytes) by (pod, namespace) / 1024 / 1024 / 1024

# HTTP request rate
sum(rate(http_requests_total[5m])) by (service)

# HTTP error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)

# Pod restart count
increase(kube_pod_container_status_restarts_total[1h])

# Disk usage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100
```

#### Configuring Prometheus

Edit Prometheus Helm values:

```bash
vim charts/prometheus/values-prod.yaml
```

```yaml
prometheus:
  prometheusSpec:
    # Data retention
    retention: 30d
    retentionSize: "100GB"

    # Resource limits
    resources:
      requests:
        cpu: 2000m
        memory: 8Gi
      limits:
        cpu: 4000m
        memory: 16Gi

    # Scrape interval
    scrapeInterval: 30s
    evaluationInterval: 30s

    # Storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
```

#### Adding ServiceMonitors

Create ServiceMonitor for application metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: django-app
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: django-app
  namespaceSelector:
    matchNames:
      - django-dev
      - django-stage
      - django-prod
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

Apply ServiceMonitor:

```bash
kubectl apply -f servicemonitor.yaml
```

#### Scaling Prometheus

```bash
# Edit values file
vim charts/prometheus/values-prod.yaml
```

```yaml
prometheus:
  prometheusSpec:
    replicas: 2  # High availability

    # Shard data across replicas
    shards: 2

    # Pod anti-affinity
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app.kubernetes.io/name: prometheus
            topologyKey: kubernetes.io/hostname
```

### Grafana Dashboards

#### Accessing Grafana

```bash
# Port forward
kubectl port-forward -n monitoring svc/grafana 3000:80

# Open http://localhost:3000
# Login: admin / dev-admin (or from terraform.tfvars)
```

#### Pre-installed Dashboards

1. **Kubernetes Cluster Overview** (ID: 7249)
   - Navigate: Dashboards → Browse → Kubernetes Cluster
   - Shows: Cluster health, node resources, pod distribution

2. **Kubernetes Pods** (ID: 6417)
   - Navigate: Dashboards → Browse → Kubernetes Pods
   - Shows: Pod metrics, container resources, lifecycle events

3. **Node Exporter** (ID: 1860)
   - Navigate: Dashboards → Browse → Node Exporter
   - Shows: System metrics, CPU, memory, disk, network

#### Importing Additional Dashboards

**Via UI:**
1. Navigate to Dashboards → Import
2. Enter dashboard ID from https://grafana.com/grafana/dashboards/
3. Select Prometheus data source
4. Click Import

**Popular Dashboards:**
- **PostgreSQL Database** (ID: 9628)
- **Django Application** (ID: 13240)
- **Nginx Ingress** (ID: 9614)
- **Kubernetes Deployment** (ID: 8588)

**Via Code:**

```bash
vim charts/grafana/values.yaml
```

```yaml
grafana:
  dashboards:
    default:
      postgres:
        gnetId: 9628
        revision: 7
        datasource: Prometheus
      django:
        gnetId: 13240
        revision: 1
        datasource: Prometheus
```

Apply changes:

```bash
cd infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars
```

#### Creating Custom Dashboards

1. Create dashboard in Grafana UI
2. Export as JSON: Dashboard Settings → JSON Model
3. Save to `charts/grafana/dashboards/custom-dashboard.json`
4. Mount in Helm values:

```yaml
grafana:
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: 'custom'
          orgId: 1
          folder: 'Custom'
          type: file
          disableDeletion: false
          options:
            path: /var/lib/grafana/dashboards/custom

  dashboards:
    custom:
      custom-dashboard:
        file: dashboards/custom-dashboard.json
```

#### Configuring Alerts

Edit Grafana values for alert configuration:

```yaml
grafana:
  grafana.ini:
    alerting:
      enabled: true

    smtp:
      enabled: true
      host: smtp.gmail.com:587
      user: your-email@gmail.com
      password: your-app-password
      from_address: alerts@yourdomain.com
      from_name: Grafana Alerts
```

#### Scaling Grafana

```bash
vim charts/grafana/values-prod.yaml
```

```yaml
grafana:
  replicas: 3

  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi

  persistence:
    enabled: true
    size: 50Gi
    storageClassName: gp3

  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app.kubernetes.io/name: grafana
          topologyKey: kubernetes.io/hostname
```

### Alertmanager Configuration

#### Accessing Alertmanager

```bash
kubectl port-forward -n monitoring \
  svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Open http://localhost:9093
```

#### Configuring Alert Routes

```yaml
# charts/prometheus/values-prod.yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack-critical'
      routes:
        - match:
            severity: critical
          receiver: slack-critical
        - match:
            severity: warning
          receiver: slack-warning

    receivers:
      - name: 'slack-critical'
        slack_configs:
          - channel: '#alerts-critical'
            title: 'Critical Alert'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

      - name: 'slack-warning'
        slack_configs:
          - channel: '#alerts-warning'
            title: 'Warning Alert'
            text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

#### Custom Alert Rules

```yaml
# charts/prometheus/values-prod.yaml
prometheus:
  prometheusSpec:
    additionalPrometheusRules:
      - name: django-app-alerts
        groups:
          - name: application
            rules:
              - alert: DjangoAppDown
                expr: up{job="django-app"} == 0
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "Django application is down"
                  description: "Django app in {{ $labels.namespace }} has been down for more than 5 minutes"

              - alert: HighErrorRate
                expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "High error rate detected"
                  description: "Error rate is {{ $value }} (>5%) for {{ $labels.service }}"

              - alert: HighRequestLatency
                expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
                for: 10m
                labels:
                  severity: warning
                annotations:
                  summary: "High request latency"
                  description: "95th percentile latency is {{ $value }}s for {{ $labels.service }}"
```

### Monitoring Troubleshooting

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# View Prometheus logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -f

# View Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f

# Check PVC status
kubectl get pvc -n monitoring

# Verify ServiceMonitor
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor django-app -n monitoring

# Test Prometheus query
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
curl 'http://localhost:9090/api/v1/query?query=up'
```

---

## Adding New Services

### Step 1: Prepare Application

Create your application structure:

```
services/my-new-app/
├── Dockerfile
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── values.yaml
├── src/
│   └── app.py
└── requirements.txt
```

### Step 2: Create Helm Chart

```bash
cd charts
helm create my-new-app
```

Edit `charts/my-new-app/values.yaml`:

```yaml
replicaCount: 1

image:
  repository: 625041985844.dkr.ecr.us-east-1.amazonaws.com/my-new-app
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 8080

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

env:
  - name: APP_ENV
    value: "development"
  - name: DB_HOST
    valueFrom:
      secretKeyRef:
        name: my-app-db-credentials
        key: DB_HOST
```

### Step 3: Create Terraform Module (Optional)

If the service requires AWS resources:

```bash
mkdir -p infrastructure/modules/my-new-service
```

```hcl
# infrastructure/modules/my-new-service/main.tf
resource "aws_s3_bucket" "my_service" {
  bucket = "${var.environment}-my-service-bucket"

  tags = var.tags
}

resource "kubernetes_secret" "my_service_config" {
  metadata {
    name      = "my-service-config"
    namespace = var.namespace
  }

  data = {
    bucket_name = aws_s3_bucket.my_service.id
  }
}
```

Add to root module:

```hcl
# infrastructure/main.tf
module "my_new_service" {
  source = "./modules/my-new-service"

  environment = var.environment
  namespace   = "my-new-app"
  tags        = var.tags
}
```

### Step 4: Create CI/CD Pipeline

Create `services/my-new-app/Jenkinsfile`:

```groovy
pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        AWS_REGION = 'us-east-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/my-new-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    sh '''
                        docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                        docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REPO}:latest
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REPO}
                        docker push ${ECR_REPO}:${IMAGE_TAG}
                        docker push ${ECR_REPO}:latest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    sh '''
                        helm upgrade --install my-new-app ./charts/my-new-app \
                            --namespace my-new-app \
                            --create-namespace \
                            --set image.tag=${IMAGE_TAG}
                    '''
                }
            }
        }
    }
}
```

### Step 5: Configure Argo CD Application

Create Argo CD application manifest:

```yaml
# charts/argocd/templates/my-new-app-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-new-app-{{ .Values.environment }}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/my-new-app.git
    targetRevision: {{ .Values.environment }}
    path: charts/my-new-app
    helm:
      valueFiles:
        - values-{{ .Values.environment }}.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: my-new-app-{{ .Values.environment }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Step 6: Add Monitoring

#### Enable Prometheus Metrics

Add to your application:

```python
# For Python/Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Metrics available at /metrics
```

#### Create ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-new-app
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: my-new-app
  namespaceSelector:
    matchNames:
      - my-new-app-dev
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

#### Import Grafana Dashboard

Add to Grafana Helm values:

```yaml
grafana:
  dashboards:
    default:
      my-new-app:
        gnetId: 12345  # Your dashboard ID
        revision: 1
        datasource: Prometheus
```

### Step 7: Deploy the Service

```bash
# Apply Terraform (if infrastructure changes were made)
cd infrastructure
terraform apply -var-file=environments/dev/terraform.tfvars

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-dev

# Deploy via Helm
helm install my-new-app ./charts/my-new-app \
  --namespace my-new-app \
  --create-namespace

# Or let Argo CD handle deployment (GitOps)
git add .
git commit -m "Add my-new-app service"
git push origin dev
```

### Step 8: Verify Deployment

```bash
# Check pods
kubectl get pods -n my-new-app

# Check services
kubectl get svc -n my-new-app

# View logs
kubectl logs -f -n my-new-app -l app=my-new-app

# Port forward for testing
kubectl port-forward -n my-new-app svc/my-new-app 8080:80

# Test application
curl http://localhost:8080
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: EKS Cluster Unreachable

```bash
# Symptom
kubectl get nodes
# Error: unable to connect to server

# Solution
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-dev

# Verify
kubectl cluster-info
```

#### Issue: Pods Stuck in Pending

```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# 1. Insufficient resources
kubectl top nodes

# 2. PVC not bound
kubectl get pvc -n <namespace>

# 3. Image pull errors
kubectl describe pod <pod-name> -n <namespace> | grep -A 10 Events

# Solutions:
# - Scale up EKS nodes
# - Check storage class exists: kubectl get storageclass
# - Verify ECR permissions
```

#### Issue: Terraform Apply Fails

```bash
# Error: Resource already exists

# Solution: Import existing resource
terraform import module.eks.aws_eks_cluster.main eks-cluster-dev

# Error: State lock
# Solution: Force unlock (use carefully)
terraform force-unlock <lock-id>

# Error: Provider version mismatch
# Solution: Upgrade providers
terraform init -upgrade
```

#### Issue: Database Connection Failed

```bash
# Check database endpoint
terraform output db_host

# Verify security group rules
aws ec2 describe-security-groups \
  --group-ids <db-security-group-id>

# Test connectivity from pod
kubectl run tmp-shell --rm -i --tty --image postgres:15 -- /bin/bash
psql -h <db-host> -U postgres -d myapp

# Check database status
aws rds describe-db-instances \
  --db-instance-identifier myapp-db-dev \
  --query 'DBInstances[0].DBInstanceStatus'
```

#### Issue: Jenkins Build Fails

```bash
# View build logs
kubectl logs -n jenkins -l app.kubernetes.io/name=jenkins -f

# Check Jenkins pod status
kubectl get pods -n jenkins
kubectl describe pod <jenkins-pod> -n jenkins

# ECR authentication issue
# Solution: Verify IRSA role permissions
aws iam get-role --role-name <jenkins-role-name>

# Restart Jenkins
kubectl rollout restart deployment/jenkins -n jenkins
```

#### Issue: Argo CD Not Syncing

```bash
# Check application status
kubectl get applications -n argocd

# View sync errors
kubectl describe application <app-name> -n argocd

# Check Argo CD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
kubectl patch application <app-name> -n argocd \
  --type merge \
  -p '{"operation":{"sync":{}}}'

# Refresh application
argocd app get <app-name> --refresh
```

#### Issue: Prometheus Not Scraping Targets

```bash
# Check targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Verify ServiceMonitor
kubectl get servicemonitor -n monitoring
kubectl describe servicemonitor <name> -n monitoring

# Check Prometheus logs
kubectl logs -n monitoring prometheus-kube-prometheus-prometheus-0

# Ensure service has correct labels
kubectl get svc <service-name> -n <namespace> --show-labels
```

#### Issue: Grafana Can't Connect to Prometheus

```bash
# Test Prometheus connectivity from Grafana pod
kubectl exec -it -n monitoring deployment/grafana -- \
  curl http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=up

# Check datasource configuration
kubectl get configmap -n monitoring grafana -o yaml

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring
```

### Logging and Debugging

#### Enable Debug Logging

```bash
# Terraform debug
export TF_LOG=DEBUG
terraform apply

# Kubectl verbose output
kubectl get pods -v=8

# Helm debug
helm install myapp ./charts/myapp --debug --dry-run
```

#### Collect Diagnostic Information

```bash
# Cluster info
kubectl cluster-info dump > cluster-info.txt

# All pod logs
kubectl logs -n <namespace> --all-containers=true --prefix=true

# Resource usage
kubectl top nodes > nodes-usage.txt
kubectl top pods --all-namespaces > pods-usage.txt

# Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Getting Help

If you encounter issues not covered here:

1. **Check pod logs**: `kubectl logs -f <pod-name> -n <namespace>`
2. **Describe resources**: `kubectl describe <resource> <name> -n <namespace>`
3. **Check events**: `kubectl get events -n <namespace>`
4. **Review Terraform state**: `terraform state list` and `terraform state show <resource>`
5. **Consult AWS console**: Check EKS, RDS, ECR, VPC for resource status
6. **Search GitHub issues**: Check repository issues for similar problems

---

## Additional Resources

### Official Documentation

- **AWS**
  - [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
  - [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
  - [AWS Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
  - [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
  - [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
  - [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)

- **Kubernetes**
  - [Kubernetes Documentation](https://kubernetes.io/docs/)
  - [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
  - [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

- **Terraform**
  - [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
  - [Terraform Language](https://www.terraform.io/language)
  - [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

- **CI/CD**
  - [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
  - [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
  - [Argo CD Documentation](https://argo-cd.readthedocs.io/)
  - [GitOps Principles](https://www.gitops.tech/)

- **Monitoring**
  - [Prometheus Documentation](https://prometheus.io/docs/)
  - [Grafana Documentation](https://grafana.com/docs/)
  - [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
  - [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

- **Helm**
  - [Helm Documentation](https://helm.sh/docs/)
  - [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)


## License

This project is licensed under the MIT License.

## Support

For issues, questions, or contributions, please open an issue in the GitHub repository.

**Enterprise Suite Infrastructure** - Built with ❤️ using AWS, Kubernetes, and modern DevOps practices.
