# Enterprise Suite Infrastructure

A comprehensive infrastructure setup for deploying Django applications across development, staging, and production environments using AWS EKS, Jenkins CI/CD, and Kubernetes.

## Architecture Overview

This project implements a complete GitOps workflow with:
- **Infrastructure as Code**: Terraform manages AWS resources (VPC, EKS, ECR)
- **Container Orchestration**: Kubernetes on AWS EKS
- **CI/CD Pipeline**: Jenkins with automated builds and deployments
- **GitOps CD**: Argo CD for continuous delivery and automatic sync
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
│   └── argocd/                 # Argo CD deployment
│       ├── Chart.yaml          # Chart with argo-cd dependency
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
- Jenkins with IRSA permissions


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

## Managing Secrets

### GitHub Credentials for Jenkins

Configured via Terraform variables in `terraform.tfvars`:

```hcl
jenkins_github_username = "your-username"
jenkins_github_token    = "ghp_token_here"
```

### Database Secrets (Stage/Prod)

```bash
kubectl create secret generic django-db-secret \
  --from-literal=database-url="postgresql://user:password@rds-endpoint:5432/dbname" \
  --namespace=django-stage

kubectl create secret generic django-db-secret \
  --from-literal=database-url="postgresql://user:password@rds-endpoint:5432/dbname" \
  --namespace=django-prod
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

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
