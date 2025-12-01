# Enterprise Suite Infrastructure

A comprehensive infrastructure setup for deploying Django applications across development, staging, and production environments using AWS EKS, Jenkins CI/CD, and Kubernetes.

## Architecture Overview

This project implements a complete GitOps workflow with:
- **Infrastructure as Code**: Terraform manages AWS resources (VPC, EKS, ECR, RDS)
- **Container Orchestration**: Kubernetes on AWS EKS
- **CI/CD Pipeline**: Jenkins with automated builds and deployments
- **GitOps CD**: Argo CD for continuous delivery and automatic sync
- **Monitoring & Observability**: Prometheus + Grafana stack for metrics and alerting
- **Database**: Aurora PostgreSQL / RDS with automated backups
- **Environment-Specific Builds**: Separate Dockerfiles for dev/stage/prod
- **Image Registry**: AWS ECR with environment-specific repositories
- **Service Exposure**: LoadBalancer for direct access (no domain required)

## Project Structure

```
enterprise-suite-infrastructure/
├── infrastructure/              # Terraform IaC
│   ├── environments/
│   │   ├── dev/                # Development environment
│   │   │   ├── backend.hcl
│   │   │   └── terraform.tfvars
│   │   ├── stage/              # Staging environment
│   │   │   ├── backend.hcl
│   │   │   └── terraform.tfvars
│   │   └── prod/               # Production environment
│   │       ├── backend.hcl
│   │       └── terraform.tfvars
│   ├── modules/
│   │   ├── vpc/                # VPC with public/private subnets
│   │   ├── ecr/                # Container registry
│   │   ├── eks/                # Kubernetes cluster + EBS CSI driver
│   │   ├── rds/                # Aurora PostgreSQL / RDS database
│   │   ├── jenkins/            # Jenkins with IRSA for ECR access
│   │   └── argocd/             # Argo CD GitOps deployment
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── charts/                      # Helm charts
│   ├── jenkins/                # Jenkins deployment
│   │   ├── values.yaml         # Base configuration
│   │   ├── values-dev.yaml     # Dev jobs
│   │   ├── values-stage.yaml   # Stage jobs
│   │   └── values-prod.yaml    # Prod jobs
│   ├── argocd/                 # Argo CD deployment
│   │   ├── Chart.yaml          # Chart with argo-cd dependency
│   │   ├── values.yaml         # Base configuration
│   │   ├── values-dev.yaml     # Dev environment
│   │   ├── values-stage.yaml   # Stage environment
│   │   └── values-prod.yaml    # Prod environment
│   └── prometheus/             # Prometheus monitoring
│       ├── Chart.yaml          # Chart with kube-prometheus-stack dependency
│       ├── values.yaml         # Base configuration
│       ├── values-dev.yaml     # Dev environment
│       ├── values-stage.yaml   # Stage environment
│       └── values-prod.yaml    # Prod environment
├── services/
│   └── django-app/
│       ├── django_app/         # Django application
│       │   ├── Dev.Dockerfile  # Development build
│       │   ├── Stage.Dockerfile # Staging build (multi-stage)
│       │   ├── Prod.Dockerfile  # Production build (multi-stage)
│       │   └── requirements.txt
│       ├── nginx/              # Nginx reverse proxy
│       ├── Jenkinsfile         # CI/CD pipeline definition
│       └── docker-compose.yml  # Local development
└── scripts/                     # Automation scripts
    ├── terraform-apply.sh      # Apply Terraform
    ├── build-and-push.sh       # Build and push to ECR
    ├── deploy.sh               # Deploy via Helm
    └── setup-environment.sh    # Complete environment setup
```

## CI/CD Pipeline (Jenkins)

### Pipeline Flow

The Jenkinsfile implements a complete GitOps workflow:

1. **Determine Environment**: Auto-detects environment based on Git branch
   - `dev` branch → Dev environment → `Dev.Dockerfile`
   - `stage` branch → Stage environment → `Stage.Dockerfile`
   - `main` branch → Prod environment → `Prod.Dockerfile`

2. **Checkout**: Clones the django-app repository

3. **Build Docker Image**: Builds using environment-specific Dockerfile
   - Uses AWS ECR for image storage
   - Tags image with `django-{env}` format

4. **Push to ECR**: Pushes built image to AWS ECR repository

5. **Update Deployment Repo**: Updates Helm values file with new image tag
   - Clones current branch from django-app repo
   - Updates `services/django-app/k8s/values-{env}.yaml`
   - Commits and pushes changes back to the same branch

6. **Deploy to EKS**: Deploys application via Helm

### Jenkins Configuration

Jenkins is deployed via Terraform with:
- **Service Account**: `jenkins-sa` with IRSA (IAM Roles for Service Accounts)
- **ECR Permissions**: Full access to push/pull images
- **Persistent Storage**: EBS volumes via AWS EBS CSI driver
- **Jobs**: Configured via Helm values files per environment

### Repository Structure

- **Infrastructure Repo**: `vladyslav-panchenko280/enterprise-suite-infrastructure`
  - Contains Terraform, Helm charts, scripts

- **Application Repo**: `vladyslav-panchenko280/django-app`
  - Contains Django code, Dockerfiles, Jenkinsfile
  - Branches: `dev`, `stage`, `main`

## Prerequisites

1. AWS CLI configured with valid credentials
2. Terraform ≥ 1.0
3. Docker for building images
4. kubectl for Kubernetes operations
5. Helm ≥ 3.0 for deploying charts
6. Git for version control
7. AWS Account ID and configured ECR repositories

## Quick Start

### 1. Create the S3 bucket for Terraform state (one-time)

```bash
aws s3api create-bucket \
  --bucket es-terraform-state-625041985844 \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket es-terraform-state-625041985844 \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket es-terraform-state-625041985844 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 2. Configure environment-specific variables

Edit `infrastructure/environments/{env}/terraform.tfvars`:

```hcl
# Update these values
jenkins_github_username = "your-github-username"
jenkins_github_token     = "ghp_your_github_token_here"
```

### 3. Full environment setup (recommended)

```bash
# Dev
./scripts/terraform-apply.sh dev

# Stage
./scripts/terraform-apply.sh stage

# Prod
./scripts/terraform-apply.sh prod
```

This creates:
- VPC with public/private subnets
- EKS cluster with node groups
- ECR repositories (es-ecr-dev, es-ecr-stage, es-ecr-prod)
- RDS Aurora PostgreSQL / Standard RDS database
- Jenkins with IRSA permissions
- Argo CD for GitOps deployments
- Kubernetes secrets for Django database credentials


## Accessing the Application

### Without Domain (LoadBalancer)

The application is exposed via AWS LoadBalancer:

```bash
# Get LoadBalancer URL
kubectl get svc -n django-dev django-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Example output:
# a1234567890abcdef-1234567890.us-east-1.elb.amazonaws.com

# Access the application
curl http://a1234567890abcdef-1234567890.us-east-1.elb.amazonaws.com
```

### Configuration Details

Since we don't have a domain:
- **Ingress**: Disabled (`ingress.enabled: false`)
- **Service Type**: LoadBalancer
- **ALLOWED_HOSTS**: Set to `"*"` (accepts any hostname)
- **Nginx server_name**: Set to `_` (wildcard, accepts all)

### Port Forwarding for Testing

```bash
kubectl port-forward -n django-dev svc/django-app 8000:8000
# Application now available at http://localhost:8000
```

## Managing Environments

### Inspect Status

```bash
# Kubernetes pods
kubectl get pods -n django-dev
kubectl get pods -n django-stage
kubectl get pods -n django-prod

# Services and LoadBalancer
kubectl get svc -n django-dev

# Deployments
kubectl get deployments -n django-dev

# Get LoadBalancer URL
kubectl get svc -n django-dev django-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Review Logs

```bash
# All pods with label selector
kubectl logs -f -n django-dev -l app.kubernetes.io/name=django-app

# Specific pod
kubectl logs -f -n django-dev <pod-name>

# Specific container in pod
kubectl logs -f -n django-dev <pod-name> -c django-app

# Previous container logs (for crashed pods)
kubectl logs -n django-dev <pod-name> --previous
```

### Updating the Application

#### Via Jenkins (GitOps)

```bash
# 1. Commit code changes to django-app repo
git add .
git commit -m "Update feature X"
git push origin dev

# 2. Jenkins automatically:
#    - Detects branch (dev)
#    - Builds with Dev.Dockerfile
#    - Pushes to ECR as django-dev
#    - Updates values-dev.yaml
#    - Deploys to EKS dev namespace
```

### Rollback

```bash
# View release history
helm history django-app -n django-dev

# Roll back to previous release
helm rollback django-app -n django-dev

# Roll back to specific revision
helm rollback django-app 2 -n django-dev
```

## RDS Module Documentation

### Module Usage Example

Basic module instantiation in `infrastructure/main.tf`:

```hcl
module "rds" {
  source = "./modules/rds"

  name                    = var.db_name
  db_name                 = var.db_database_name
  username                = var.db_username
  password                = var.db_password
  vpc_id                  = module.vpc.vpc_id
  subnet_private_ids      = module.vpc.private_subnet_ids
  subnet_public_ids       = module.vpc.public_subnet_ids

  use_aurora              = var.db_use_aurora
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage

  multi_az                = var.db_multi_az
  publicly_accessible     = var.db_publicly_accessible
  backup_retention_period = var.db_backup_retention_period

  db_parameters           = var.db_parameters
  tags                    = var.tags
}
```

### Database Variables

**Required:**
- `db_name` - Database instance or cluster name
- `db_database_name` - Initial database name
- `db_username` - Master user username
- `db_password` - Master user password (use AWS Secrets Manager for production)

**Core Configuration:**
- `db_engine` - Database engine type: `postgres`, `mysql`, `mariadb`, `oracle-se2`, `sqlserver-se` (default: `postgres`)
- `db_engine_version` - Engine version for standard RDS (default: `14.7`)
- `db_use_aurora` - Enable Aurora (default: `false`)
- `db_instance_class` - Instance class: `db.t3.micro`, `db.t3.small`, `db.r5.large`, `db.r5.xlarge`, etc. (default: `db.t3.micro`)
- `db_allocated_storage` - Storage size in GB (default: `20`, Aurora scales automatically)

**Availability & Backup:**
- `db_multi_az` - Enable Multi-AZ for high availability (default: `false`)
- `db_publicly_accessible` - Allow public internet access to database (default: `false`)
- `db_backup_retention_period` - Number of days to retain backups
- `db_aurora_instance_count` - Total Aurora instances (default: `2`)

**Performance Parameters:**

The `db_parameters` variable accepts key-value pairs for database tuning:

```hcl
db_parameters = {
  max_connections = 100    # Maximum concurrent connections
  log_statement   = "all"   # Query logging level: "all", "mod", "ddl", "none"
  work_mem        = "4MB"   # Memory for sorting and hashing operations
}
```

**Parameter Values by Environment:**

- **Development**: `max_connections: 100`, `log_statement: "all"`, `work_mem: "4MB"`
- **Staging**: `max_connections: 300`, `log_statement: "mod"`, `work_mem: "8MB"`
- **Production**: `max_connections: 1000`, `log_statement: "mod"`, `work_mem: "32MB"`

### How to Change Database Configuration

#### 1. Change Database Type (RDS ↔ Aurora)

**Switch from Standard RDS to Aurora:**

```hcl
# In terraform.tfvars
db_use_aurora            = true
db_aurora_instance_count = 2
db_engine_version        = "15.3"
```

**Switch from Aurora to Standard RDS:**

```hcl
# In terraform.tfvars
db_use_aurora            = false
db_engine                = "postgres"
db_engine_version        = "15.2"
db_allocated_storage     = 20
```

#### 2. Change Database Engine

**PostgreSQL:**
```hcl
db_engine         = "postgres"
db_engine_version = "15.2"
```

**MySQL:**
```hcl
db_engine         = "mysql"
db_engine_version = "8.0.35"
```

**MariaDB:**
```hcl
db_engine         = "mariadb"
db_engine_version = "10.6.14"
```

**Oracle SE2:**
```hcl
db_engine         = "oracle-se2"
db_engine_version = "19.0.0.0.ru-2024-01.1"
```

#### 3. Change Instance Class (Performance Tier)

**Budget Options (Development/Testing):**
- `db.t3.micro` - 1 vCPU, 1 GB RAM
- `db.t3.small` - 1 vCPU, 2 GB RAM
- `db.t3.medium` - 2 vCPU, 4 GB RAM

**Standard Options (General Purpose):**
- `db.m5.large` - 2 vCPU, 8 GB RAM
- `db.m5.xlarge` - 4 vCPU, 16 GB RAM
- `db.m5.2xlarge` - 8 vCPU, 32 GB RAM

**Memory Optimized (High Performance):**
- `db.r5.large` - 2 vCPU, 16 GB RAM
- `db.r5.xlarge` - 4 vCPU, 32 GB RAM
- `db.r6g.large` - 2 vCPU, 16 GB RAM (Graviton2, more cost-efficient)
- `db.r6g.xlarge` - 4 vCPU, 32 GB RAM

**Example: Scale up for production**
```hcl
db_instance_class = "db.r6g.xlarge"  # Powerful instance for production
```

#### 4. Adjust Database Parameters

Add custom parameters through the `parameters` variable in the RDS module (in `variables.tf`):

```hcl
# In terraform.tfvars
parameters = {
  "shared_preload_libraries" = "pg_stat_statements"
  "maintenance_work_mem"     = "256MB"
  "effective_cache_size"     = "2GB"
  "random_page_cost"         = "1.1"
}
```

Combine standard and custom parameters:
```hcl
db_parameters = {
  max_connections = 500
  log_statement   = "mod"
  work_mem        = "16MB"
}

parameters = {
  "shared_preload_libraries" = "pg_stat_statements"
  "effective_cache_size"     = "4GB"
}
```

### Database Configuration in terraform.tfvars

All database settings are configured via environment-specific `terraform.tfvars` files

### Kubernetes Database Secret

Terraform automatically creates a Kubernetes secret with database credentials:

```bash
# Verify the secret was created
kubectl get secret django-db-credentials -o yaml

# Secret contains:
# - DB_HOST: Aurora cluster endpoint / RDS address
# - DB_PORT: 5432 (default)
# - DB_NAME: Database name
# - DB_USER: Master username
# - DB_PASSWORD: Master password
```

### Django Integration

Django settings automatically use the database credentials:

**In Kubernetes pods**, environment variables are injected from the secret:
```yaml
env:
  - name: DB_HOST
    valueFrom:
      secretKeyRef:
        name: django-db-credentials
        key: DB_HOST
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: django-db-credentials
        key: DB_PASSWORD
```

**In `settings.py`**, Django reads these env vars:
```python
if os.environ.get('DB_HOST'):
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.environ.get('DB_NAME', 'myapp'),
            'USER': os.environ.get('DB_USER', 'postgres'),
            'PASSWORD': os.environ.get('DB_PASSWORD', ''),
            'HOST': os.environ.get('DB_HOST'),
            'PORT': os.environ.get('DB_PORT', '5432'),
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
```

### Database Connection

```bash
# Get database endpoint
terraform output db_host

# Connect to database
psql -h <db_host> -U postgres -d myapp

# Connection string for Django
DATABASE_URL="postgres://postgres:password@<db_host>:5432/myapp"
```

### Database Migrations

```bash
# From within a Django pod
kubectl exec -it -n django-dev <pod-name> -- python manage.py migrate

# Or via local environment with port forwarding
kubectl port-forward -n django-dev svc/postgres 5432:5432 &
python manage.py migrate --database=<remote-db>
```

### Backing Up and Restoring

Aurora automatically creates backups. For manual backup:

```bash
# Using AWS CLI
aws rds create-db-cluster-snapshot \
  --db-cluster-snapshot-identifier myapp-snapshot \
  --db-cluster-identifier myapp-db-prod

# Check snapshot status
aws rds describe-db-cluster-snapshots \
  --db-cluster-snapshot-identifier myapp-snapshot
```

### Monitoring Database Performance

```bash
# AWS CloudWatch metrics (optional - requires CloudWatch configuration)
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-db-prod \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-02T00:00:00Z \
  --period 300 \
  --statistics Average
```

## Managing Secrets

### GitHub Credentials for Jenkins

Configured via Terraform variables in `terraform.tfvars`:

```hcl
jenkins_github_username = "your-username"
jenkins_github_token    = "ghp_token_here"
```

### Database Secrets (Production)

For production environments, store `db_password` in AWS Secrets Manager instead of tfvars:

```bash
# Store password in Secrets Manager
aws secretsmanager create-secret \
  --name prod/db-password \
  --secret-string "YourSecurePassword123!"

# Reference in Terraform (configure in prod tfvars)
db_password = "YourSecurePassword123!"  # Retrieved from Secrets Manager
```

### Django SECRET_KEY

```bash
token=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

echo $token

kubectl create secret generic django-secret \
  --from-literal=secret-key="$token" \
  --namespace=django-prod
```

## Monitoring and Troubleshooting

### Exec into a Pod

```bash
kubectl exec -it -n django-dev <pod-name> -- /bin/bash
```

### Django Management Commands

```bash
# Migrations
kubectl exec -it -n django-dev <pod-name> -- python manage.py migrate

# Create superuser
kubectl exec -it -n django-dev <pod-name> -- python manage.py createsuperuser

# Collect static files
kubectl exec -it -n django-dev <pod-name> -- python manage.py collectstatic --noinput
```

### Jenkins Access

```bash
# Get Jenkins admin password
kubectl get secret -n jenkins jenkins-dev-admin-password \
  -o jsonpath='{.data.password}' | base64 -d

# Port forward to Jenkins
kubectl port-forward -n jenkins svc/jenkins-dev 8080:8080

# Access Jenkins at http://localhost:8080
```

## Cleaning Up

### Remove Application

```bash
# Uninstall Helm release
helm uninstall django-app -n django-dev

# Delete namespace
kubectl delete namespace django-dev
```

### Destroy Infrastructure

```bash
cd infrastructure

# Initialize Terraform
terraform init -backend-config=environments/dev/backend.hcl -reconfigure

# Destroy resources
terraform destroy -var-file=environments/dev/terraform.tfvars
```

### Delete ECR Images

```bash
# List images
aws ecr list-images --repository-name es-ecr-dev --region us-east-1

# Delete all images in repository
aws ecr batch-delete-image \
  --repository-name es-ecr-dev \
  --region us-east-1 \
  --image-ids "$(aws ecr list-images --repository-name es-ecr-dev --region us-east-1 --query 'imageIds[*]' --output json)" || true
```

## Jenkins Pipeline Details

### Environment Detection

```groovy
if (branch == 'main') {
    env.DEPLOY_ENV = 'prod'
    env.DOCKERFILE = 'Prod.Dockerfile'
} else if (branch == 'stage') {
    env.DEPLOY_ENV = 'stage'
    env.DOCKERFILE = 'Stage.Dockerfile'
} else if (branch == 'dev') {
    env.DEPLOY_ENV = 'dev'
    env.DOCKERFILE = 'Dev.Dockerfile'
}
```

### GitOps Update

```groovy
stage('Update Deployment Repo') {
    steps {
        script {
            withCredentials([...]) {
                sh '''
                    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
                    git clone -b ${CURRENT_BRANCH} https://${GIT_USER}:${GIT_PASS}@github.com/vladyslav-panchenko280/django-jenkins-app.git .

                    # Update values file
                    sed -i "s|tag: .*|tag: \"django-${DEPLOY_ENV}\"|g" \
                      charts/django-app/values-${DEPLOY_ENV}.yaml

                    git add charts/django-app/values-${DEPLOY_ENV}.yaml
                    git commit -m "Update django-app image to django-${DEPLOY_ENV}"
                    git push https://${GIT_USER}:${GIT_PASS}@github.com/vladyslav-panchenko280/django-jenkins-app.git ${CURRENT_BRANCH}
                '''
            }
        }
    }
}
```

## Argo CD (GitOps)

Argo CD provides continuous delivery with automatic synchronization from Git.

### Features

- **Automatic Sync**: Monitors Git repository and automatically deploys changes
- **Self-Healing**: Automatically reverts manual changes in cluster
- **Multi-Environment**: Separate configurations for dev/stage/prod
- **IRSA Integration**: Uses IAM Roles for Service Accounts for ECR access

### Architecture

```
Git Repository (django-jenkins-app)
        │
        ▼
   Argo CD Application
        │
        ▼
   Helm Chart (charts/django-app)
        │
        ▼
   Kubernetes Deployment
```

### Configuration

Argo CD Application is configured in `charts/argocd/templates/application.yaml`:
- **Source**: Git repository with Helm chart
- **Target Revision**: Branch based on environment (main for prod, environment name for others)
- **Sync Policy**: Automated with prune and self-heal enabled

### Accessing Argo CD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080
# Login: admin / <password from above>
```

### Argo CD Application Status

```bash
# List all applications
kubectl get applications -n argocd

# Get detailed status
kubectl get applications -n argocd -o wide

# Describe application
kubectl describe application django-app-dev -n argocd
```

### Testing Auto-Sync

1. Make a change to `charts/django-app/values-dev.yaml` in Git
2. Commit and push the change
3. Wait for Argo CD to detect the change (default: 3 minutes)
4. Verify sync status:

```bash
kubectl get applications -n argocd
# Status should show "Synced" and "Healthy"
```

### Manual Sync

```bash
# Using argocd CLI
argocd app sync django-app-dev

# Or trigger via kubectl
kubectl patch application django-app-dev -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

## Prometheus Monitoring Stack

This project includes a comprehensive monitoring solution using the Prometheus ecosystem.

### Architecture

The monitoring stack includes:
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and dashboarding
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Hardware and OS metrics
- **Kube State Metrics**: Kubernetes cluster state metrics
- **Prometheus Operator**: Kubernetes-native Prometheus management

### Deployment via Terraform

Prometheus is deployed automatically when you apply Terraform:

```bash
# Deploy infrastructure with monitoring
./scripts/terraform-apply.sh dev
```

The Prometheus module is configured in [infrastructure/main.tf](infrastructure/main.tf:89-107) and creates:
- `monitoring` namespace
- Prometheus server with persistent storage
- Grafana with preconfigured dashboards
- Alertmanager for alert routing
- ServiceMonitors for automatic metric discovery

### Environment-Specific Configuration

#### Development
- **Resources**: Minimal (dev testing)
- **Retention**: 7 days
- **Storage**: 20GB
- **Replicas**: Single instance
- **Access**: NodePort services
- **Password**: `dev-admin`

#### Staging
- **Resources**: Balanced (pre-production testing)
- **Retention**: 15 days
- **Storage**: 40GB
- **Replicas**: 2 Prometheus, 2 Alertmanager
- **Access**: Internal LoadBalancer
- **Password**: `stage-admin-secure`

#### Production
- **Resources**: High availability
- **Retention**: 30 days
- **Storage**: 100GB
- **Replicas**: 2 Prometheus, 3 Alertmanager
- **Access**: Internal LoadBalancer
- **Password**: Use AWS Secrets Manager
- **Features**: Pod anti-affinity, custom alerts

### Accessing Monitoring UIs

#### Prometheus UI

```bash
# Get Prometheus service
kubectl get svc -n monitoring

# Port forward for local access
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Open http://localhost:9090
```

### Metrics Collection

#### Automatic Kubernetes Monitoring

The stack automatically monitors:
- Node metrics (CPU, memory, disk, network)
- Pod metrics (resource usage, restarts, status)
- Container metrics (CPU, memory, filesystem)
- Kubernetes API server metrics
- Kubelet metrics
- CoreDNS metrics

#### Adding Application Metrics

To expose metrics from your Django application:

**1. Add Prometheus client to Django:**

```python
# requirements.txt
django-prometheus==2.3.1
```

```python
# settings.py
INSTALLED_APPS = [
    'django_prometheus',
    # ... other apps
]

MIDDLEWARE = [
    'django_prometheus.middleware.PrometheusBeforeMiddleware',
    # ... other middleware
    'django_prometheus.middleware.PrometheusAfterMiddleware',
]
```

```python
# urls.py
from django.urls import path, include

urlpatterns = [
    path('', include('django_prometheus.urls')),
    # ... other urls
]
```

**2. Create ServiceMonitor for Django app:**

```yaml
# In your Helm chart values
prometheus:
  monitor:
    enabled: true
    interval: 30s
    path: /metrics
```

**3. Or create custom ServiceMonitor:**

```bash
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: django-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: django-app
  endpoints:
    - port: http
      path: /metrics
      interval: 30s
EOF
```

### Custom Alerts

Production environment includes sample alerts:

- **DjangoAppDown**: Triggers when application is unavailable
- **HighRequestLatency**: 95th percentile > 1s for 10 minutes
- **HighErrorRate**: 5xx errors > 5% for 5 minutes

Add custom alerts by editing [charts/prometheus/values-prod.yaml](charts/prometheus/values-prod.yaml:204-249).

### Alerting Configuration

Configure alert receivers in terraform.tfvars:

```hcl
prometheus_set_values = {
  "alertmanager.config.receivers[0].slack_configs[0].api_url" = "https://hooks.slack.com/services/YOUR/WEBHOOK"
  "alertmanager.config.receivers[0].slack_configs[0].channel" = "#alerts"
}
```

Or update [values-{env}.yaml](charts/prometheus/) files directly.

### Troubleshooting

#### Check Prometheus targets:

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit http://localhost:9090/targets
```

#### View Prometheus logs:

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus
```

#### Reset Grafana password:

```bash
# Get admin password from Helm values
terraform output -json | jq -r '.prometheus_grafana_password.value'

# Or reset via kubectl
kubectl exec -it -n monitoring deployment/prometheus-grafana -- grafana-cli admin reset-admin-password newpassword
```

### Storage Management

#### Check PVC usage:

```bash
kubectl get pvc -n monitoring
kubectl describe pvc -n monitoring
```

### Backup and Restore

#### Backup Prometheus data:

```bash
# Create snapshot of Prometheus PVC
kubectl exec -n monitoring prometheus-kube-prometheus-prometheus-0 -- tar czf /tmp/prometheus-backup.tar.gz /prometheus

# Copy backup
kubectl cp monitoring/prometheus-kube-prometheus-prometheus-0:/tmp/prometheus-backup.tar.gz ./prometheus-backup.tar.gz
```

### Performance Tuning

For production workloads, tune Prometheus in [values-prod.yaml](charts/prometheus/values-prod.yaml):

```yaml
prometheus:
  prometheusSpec:
    # Adjust retention based on storage
    retention: 30d
    retentionSize: "100GB"

    # Scale resources for large clusters
    resources:
      requests:
        cpu: 2000m
        memory: 8Gi
      limits:
        cpu: 4000m
        memory: 16Gi

    # Adjust scrape intervals
    scrapeInterval: 30s
    evaluationInterval: 30s
```

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.html)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [Django Database Settings](https://docs.djangoproject.com/en/stable/ref/settings/#databases)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Kube-Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## RDS Module Reusability

The RDS module is fully reusable and can be instantiated multiple times for different databases:

```hcl
# Additional database instance example
module "rds_analytics" {
  source = "./modules/rds"

  name                  = "analytics-db"
  db_name              = "analytics"
  use_aurora           = true
  aurora_instance_count = 2
  instance_class       = "db.r6g.large"
  db_username          = "analytics_user"
  password             = var.analytics_db_password

  subnet_private_ids      = module.vpc.private_subnet_ids
  subnet_public_ids       = module.vpc.public_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  multi_az                = true
  backup_retention_period = 30

  tags = var.tags
}
```

Each module instance creates:
- Independent RDS instance or Aurora cluster
- Separate security group with database rules
- Dedicated subnet group
- Custom parameter groups
- Unique outputs for application connection
