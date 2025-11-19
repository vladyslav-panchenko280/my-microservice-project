#!/bin/bash

# Deploy application to Kubernetes
# Usage: ./scripts/deploy.sh <environment>
# Example: ./scripts/deploy.sh dev

set -e

# Get script directory and load colors library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colors.sh"

# Check arguments
if [ "$#" -ne 1 ]; then
    print_error "Error: Environment required"
    echo "Usage: $0 <environment>"
    echo "Environments: dev, stage, prod"
    exit 1
fi

ENV=$1

# Validate environment
if [[ ! "$ENV" =~ ^(dev|stage|prod)$ ]]; then
    print_error "Error: Invalid environment. Use dev, stage, or prod"
    exit 1
fi

# Configuration
CLUSTER_NAME="es-eks-${ENV}"
NAMESPACE="django-${ENV}"
RELEASE_NAME="django-app"
CHART_PATH="charts/django-app"
VALUES_FILE="charts/django-app/values-${ENV}.yaml"

print_section "Deploying to ${ENV} environment"
print_info "Cluster: ${CLUSTER_NAME}"
print_info "Namespace: ${NAMESPACE}"
echo

# Update kubeconfig
print_step "Updating kubeconfig for cluster ${CLUSTER_NAME}..."
aws eks update-kubeconfig --region us-east-1 --name ${CLUSTER_NAME}

# Verify connection
print_step "Verifying cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Error: Cannot connect to cluster"
    exit 1
fi
print_check "Connected to cluster"

# Create namespace if it doesn't exist
print_step "Ensuring namespace ${NAMESPACE} exists..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create ECR pull secret
print_step "Creating ECR pull secret..."
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Get ECR token
ECR_TOKEN=$(aws ecr get-login-password --region ${AWS_REGION})

# Create or update secret
kubectl create secret docker-registry ecr-secret \
    --docker-server=${ECR_REGISTRY} \
    --docker-username=AWS \
    --docker-password=${ECR_TOKEN} \
    --namespace=${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -

print_check "ECR secret created"

# Create database secret (if needed)
if [ "$ENV" == "dev" ]; then
    print_step "Creating database secret for dev environment..."
    kubectl create secret generic django-db-secret \
        --from-literal=database-url="postgresql://django:devpassword@postgresql:5432/django_dev" \
        --namespace=${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
else
    print_warning "Note: For ${ENV}, ensure django-db-secret is created with production database URL"
fi

# Deploy with Helm
print_step "Deploying application with Helm..."
helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
    --namespace ${NAMESPACE} \
    --values ${VALUES_FILE} \
    --set image.tag=django-${ENV} \
    --set nginx.image.tag=nginx-${ENV} \
    --wait \
    --timeout 5m

print_check "Application deployed successfully"

# Show deployment status
print_subsection "Deployment Status"
kubectl get pods -n ${NAMESPACE}
kubectl get services -n ${NAMESPACE}
kubectl get ingress -n ${NAMESPACE}

# Get application URL
print_success "Application deployed to ${ENV} environment"
echo "To check logs:"
echo "  kubectl logs -f -n ${NAMESPACE} -l app.kubernetes.io/name=django-app"
echo "To port-forward locally:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/${RELEASE_NAME} 8000:8000"


