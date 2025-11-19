#!/bin/bash

# Complete setup for an environment (Terraform + Build + Deploy)
# Usage: ./scripts/setup-environment.sh <environment>
# Example: ./scripts/setup-environment.sh dev

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

print_section "Complete Environment Setup: ${ENV}"

# Step 1: Apply Terraform
print_header "Step 1/3: Applying Terraform infrastructure"
./scripts/terraform-apply.sh ${ENV}

# Wait for infrastructure to be ready
print_warning "Waiting 30 seconds for infrastructure to stabilize..."
sleep 30

# Step 2: Build and push images
print_header "Step 2/3: Building and pushing Docker images"
./scripts/build-and-push.sh ${ENV}

# Step 3: Deploy to Kubernetes
print_header "Step 3/3: Deploying to Kubernetes"
./scripts/deploy.sh ${ENV}

print_section "Environment ${ENV} setup complete!"
echo "Your application is now running in the ${ENV} environment."
echo "Useful commands:"
echo "  - Check pods: kubectl get pods -n django-${ENV}"
echo "  - View logs: kubectl logs -f -n django-${ENV} -l app.kubernetes.io/name=django-app"
echo "  - Port forward: kubectl port-forward -n django-${ENV} svc/django-app 8000:8000"
echo ""

