#!/bin/bash

# Apply Terraform configuration for specific environment
# Usage: ./scripts/terraform-apply.sh <environment>
# Example: ./scripts/terraform-apply.sh dev

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
INFRA_DIR="infrastructure"
ENV_DIR="${INFRA_DIR}/environments/${ENV}"
BACKEND_CONFIG="${ENV_DIR}/backend.hcl"
TFVARS_FILE="${ENV_DIR}/terraform.tfvars"

print_section "Applying Terraform for ${ENV} environment"

# Check if files exist
if [ ! -f "${BACKEND_CONFIG}" ]; then
    print_error "Error: Backend config not found: ${BACKEND_CONFIG}"
    exit 1
fi

if [ ! -f "${TFVARS_FILE}" ]; then
    print_error "Error: Terraform variables file not found: ${TFVARS_FILE}"
    exit 1
fi

# Change to infrastructure directory
cd ${INFRA_DIR}

# Initialize Terraform with backend config
print_step "Initializing Terraform..."
terraform init -backend-config=environments/${ENV}/backend.hcl -reconfigure

# Validate configuration
print_step "Validating Terraform configuration..."
terraform validate
print_check "Configuration is valid"

# Plan
print_step "Creating Terraform plan..."
terraform plan -var-file=environments/${ENV}/terraform.tfvars -out=${ENV}.tfplan

# Ask for confirmation
print_warning "Review the plan above. Do you want to apply? (yes/no)"
read -r CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_error "Terraform apply cancelled"
    rm -f ${ENV}.tfplan
    exit 0
fi

# Apply
print_step "Applying Terraform configuration..."
terraform apply ${ENV}.tfplan

# Clean up plan file
rm -f ${ENV}.tfplan

print_success "Terraform applied successfully for ${ENV} environment"
print_subsection "Infrastructure outputs"
terraform output

print_info "Next steps:"
echo "  1. Build and push Docker images: ./scripts/build-and-push.sh ${ENV}"
echo "  2. Deploy application: ./scripts/deploy.sh ${ENV}"

