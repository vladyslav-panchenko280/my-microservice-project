# My Microservice Project Deployment Guide

A concise reference for provisioning infrastructure, building images, and deploying the Django application across development, staging, production, and local environments.

## Project Structure

```
my-microservice-project/
├── infrastructure/              # Terraform configuration
│   ├── environments/
│   │   ├── dev/                # Dev environment
│   │   │   ├── backend.hcl
│   │   │   └── terraform.tfvars
│   │   ├── stage/              # Stage environment
│   │   │   ├── backend.hcl
│   │   │   └── terraform.tfvars
│   │   └── prod/               # Prod environment
│   │       ├── backend.hcl
│   │       └── terraform.tfvars
│   ├── modules/                # Terraform modules
│   ├── main.tf
│   ├── variables.tf
│   └── backend.tf
├── charts/                      # Helm charts
│   └── django-app/
│       ├── values.yaml         # Base values
│       ├── values-dev.yaml     # Dev configuration
│       ├── values-stage.yaml   # Stage configuration
│       └── values-prod.yaml    # Prod configuration
├── services/                    # Microservices
│   └── django-app/
│       ├── django_app/         # Django code
│       ├── nginx/              # Nginx configuration
│       └── docker-compose.yml  # Local development
└── scripts/                     # Automation
    ├── terraform-apply.sh      # Apply Terraform
    ├── build-and-push.sh       # Build and push images
    ├── deploy.sh               # Deploy to Kubernetes
    └── setup-environment.sh    # Full environment setup
```

## Prerequisites

1. AWS CLI configured with valid credentials
2. Terraform ≥ 1.0
3. Docker for building images
4. kubectl for Kubernetes operations
5. Helm ≥ 3.0 for deploying charts
6. Git for version control

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

### 2. Full environment setup (recommended)

The fastest way is to run the convenience script:

```bash
# Dev environment
./scripts/setup-environment.sh dev

# Stage environment
./scripts/setup-environment.sh stage

# Prod environment
./scripts/setup-environment.sh prod
```

This script automatically:
1. Applies the Terraform configuration
2. Builds and pushes Docker images to ECR
3. Deploys the application to Kubernetes

### 3. Step-by-step setup (alternative)

If you prefer more control, execute each step manually.

#### Step 1: Apply Terraform

```bash
# Dev
./scripts/terraform-apply.sh dev

# Stage
./scripts/terraform-apply.sh stage

# Prod
./scripts/terraform-apply.sh prod
```

#### Step 2: Build and push Docker images

```bash
# Build all services for dev
./scripts/build-and-push.sh dev

# Only Django
./scripts/build-and-push.sh dev django-app

# Only Nginx
./scripts/build-and-push.sh dev nginx
```

#### Step 3: Deploy to Kubernetes

```bash
# Dev
./scripts/deploy.sh dev

# Stage
./scripts/deploy.sh stage

# Prod
./scripts/deploy.sh prod
```

## Local Development

Use Docker Compose for local workflows:

```bash
cd services/django-app

# Create .env
cat > .env <<EOF
POSTGRES_DB=django_dev
POSTGRES_USER=django
POSTGRES_PASSWORD=devpassword
DATABASE_URL=postgresql://django:devpassword@db:5432/django_dev
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
EOF

# Start services
docker-compose up -d

# Tail logs
docker-compose logs -f

# Stop services
docker-compose down
```

Application endpoints:
- Django: http://localhost:8000
- Nginx: http://localhost:80
- PostgreSQL: localhost:5432

## Managing Environments

### Inspect status

```bash
# Kubernetes pods
kubectl get pods -n django-dev
kubectl get pods -n django-stage
kubectl get pods -n django-prod

# Services
kubectl get svc -n django-dev

# Ingress
kubectl get ingress -n django-dev
```

### Review logs

```bash
# All pods
kubectl logs -f -n django-dev -l app.kubernetes.io/name=django-app

# Specific pod
kubectl logs -f -n django-dev <pod-name>

# Specific container
kubectl logs -f -n django-dev <pod-name> -c django-app
```

### Port forwarding for testing

```bash
kubectl port-forward -n django-dev svc/django-app 8000:8000
# Application now available at http://localhost:8000
```

### Updating the application

```bash
# 1. Modify code
# 2. Build a new image
./scripts/build-and-push.sh dev

# 3. Roll out the update
./scripts/deploy.sh dev
```

### Rollback

```bash
# Release history
helm history django-app -n django-dev

# Roll back to previous
helm rollback django-app -n django-dev

# Roll back to a specific revision
helm rollback django-app 2 -n django-dev
```

## Managing Secrets

### Database secrets (stage/prod)

```bash
# Stage
kubectl create secret generic django-db-secret \
  --from-literal=database-url="postgresql://user:password@rds-endpoint:5432/dbname" \
  --namespace=django-stage

# Prod
kubectl create secret generic django-db-secret \
  --from-literal=database-url="postgresql://user:password@rds-endpoint:5432/dbname" \
  --namespace=django-prod
```

### Django SECRET_KEY

```bash
# Generate
token=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

echo $token

# Store
kubectl create secret generic django-secret \
  --from-literal=secret-key="$token" \
  --namespace=django-prod
```

## Monitoring and Troubleshooting

### Exec into a pod

```bash
kubectl exec -it -n django-dev <pod-name> -- /bin/bash
```

### Django management commands

```bash
# Migrations
kubectl exec -it -n django-dev <pod-name> -- python manage.py migrate

# Create superuser
kubectl exec -it -n django-dev <pod-name> -- python manage.py createsuperuser

# Collect static files
kubectl exec -it -n django-dev <pod-name> -- python manage.py collectstatic --noinput
```

### Resource usage

```bash
# CPU & memory
kubectl top pods -n django-dev
kubectl top nodes

# Pod description
kubectl describe pod -n django-dev <pod-name>

# Recent events
kubectl get events -n django-dev --sort-by='.lastTimestamp'
```

## Environment Comparison

| Parameter             | Dev          | Stage        | Prod          |
|-----------------------|--------------|--------------|---------------|
| Replicas              | 1            | 2            | 3             |
| Autoscaling           | Disabled     | 2-5 pods     | 3-10 pods     |
| Resources (CPU)       | 250m-500m    | 500m-1000m   | 1000m-2000m   |
| Resources (Memory)    | 256Mi-512Mi  | 512Mi-1Gi    | 1Gi-2Gi       |
| Debug mode            | Enabled      | Disabled     | Disabled      |
| PostgreSQL            | In-cluster   | RDS          | RDS           |
| SSL/TLS               | Optional     | Required     | Required      |
| Backup cadence        | None         | Daily        | Hourly        |

## Cleaning Up

### Remove application

```bash
helm uninstall django-app -n django-dev
kubectl delete namespace django-dev
```

### Destroy infrastructure

```bash
cd infrastructure

terraform init -backend-config=environments/dev/backend.hcl -reconfigure
terraform destroy -var-file=environments/dev/terraform.tfvars
```

## Troubleshooting

### Pod fails to start

```bash
kubectl describe pod -n django-dev <pod-name>
kubectl logs -n django-dev <pod-name>
kubectl get events -n django-dev
```

### ECR issues

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

aws ecr describe-repositories --region us-east-1
aws ecr describe-images --repository-name es-ecr-dev --region us-east-1
```

### Terraform issues

```bash
terraform refresh -var-file=environments/dev/terraform.tfvars
terraform show
terraform import -var-file=environments/dev/terraform.tfvars <resource> <id>
```

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
