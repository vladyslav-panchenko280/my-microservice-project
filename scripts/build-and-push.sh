#!/bin/bash

# Build and push Docker images to ECR
# Usage: ./scripts/build-and-push.sh <environment> [service]
# Example: ./scripts/build-and-push.sh dev django-app

set -e

# Get script directory and load colors library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/colors.sh"

# Check arguments
if [ "$#" -lt 1 ]; then
    print_error "Error: Environment required"
    echo "Usage: $0 <environment> [service]"
    echo "Environments: dev, stage, prod"
    echo "Services: django-app (default: all)"
    exit 1
fi

ENV=$1
SERVICE=${2:-"all"}

# Validate environment
if [[ ! "$ENV" =~ ^(dev|stage|prod)$ ]]; then
    print_error "Error: Invalid environment. Use dev, stage, or prod"
    exit 1
fi

# AWS Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="es-ecr-${ENV}"

print_section "Building and pushing images for ${ENV} environment"
print_info "ECR Repository: ${ECR_REGISTRY}/${ECR_REPO}"

# Login to ECR
print_step "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ECR_REGISTRY}

# Build and push Django app
build_django() {
    print_subsection "Building Django app"

    cd services/django-app/django_app

    # Select environment-specific Dockerfile
    case $ENV in
        dev)
            DOCKERFILE="Dev.Dockerfile"
            ;;
        stage)
            DOCKERFILE="Stage.Dockerfile"
            ;;
        prod)
            DOCKERFILE="Prod.Dockerfile"
            ;;
    esac

    print_info "Using Dockerfile: ${DOCKERFILE}"

    # Build image
    print_step "Building Docker image..."
    docker build \
        -f ${DOCKERFILE} \
        -t django-app:${ENV} \
        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
        --build-arg VCS_REF=$(git rev-parse --short HEAD) \
        --build-arg VERSION=${ENV}-$(git rev-parse --short HEAD) \
        .

    # Tag for ECR
    print_step "Tagging images..."
    docker tag django-app:${ENV} ${ECR_REGISTRY}/${ECR_REPO}:django-${ENV}
    docker tag django-app:${ENV} ${ECR_REGISTRY}/${ECR_REPO}:django-${ENV}-$(git rev-parse --short HEAD)

    # Push to ECR
    print_step "Pushing Django image to ECR..."
    docker push ${ECR_REGISTRY}/${ECR_REPO}:django-${ENV}
    docker push ${ECR_REGISTRY}/${ECR_REPO}:django-${ENV}-$(git rev-parse --short HEAD)

    print_check "Django app pushed successfully"

    cd ../../..
}

# Build and push Nginx
build_nginx() {
    print_subsection "Building Nginx"
    
    cd services/django-app/nginx
    
    # Create Dockerfile for Nginx if it doesn't exist
    if [ ! -f Dockerfile ]; then
        print_warning "Dockerfile not found, creating default..."
        cat > Dockerfile <<EOF
FROM nginx:1.25-alpine

COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF
    fi
    
    # Build image
    print_step "Building Docker image..."
    docker build -t nginx-django:${ENV} .
    
    # Tag for ECR
    print_step "Tagging images..."
    docker tag nginx-django:${ENV} ${ECR_REGISTRY}/${ECR_REPO}:nginx-${ENV}
    docker tag nginx-django:${ENV} ${ECR_REGISTRY}/${ECR_REPO}:nginx-${ENV}-$(git rev-parse --short HEAD)
    
    # Push to ECR
    print_step "Pushing Nginx image to ECR..."
    docker push ${ECR_REGISTRY}/${ECR_REPO}:nginx-${ENV}
    docker push ${ECR_REGISTRY}/${ECR_REPO}:nginx-${ENV}-$(git rev-parse --short HEAD)
    
    print_check "Nginx pushed successfully"
    
    cd ../../..
}

# Build based on service argument
case $SERVICE in
    django-app)
        build_django
        ;;
    nginx)
        build_nginx
        ;;
    all)
        build_django
        build_nginx
        ;;
    *)
        print_error "Error: Unknown service ${SERVICE}"
        echo "Available services: django-app, nginx, all"
        exit 1
        ;;
esac

print_success "All images built and pushed successfully for ${ENV} environment"
print_info "Images pushed:"
echo "  - ${ECR_REGISTRY}/${ECR_REPO}:django-${ENV}"
echo "  - ${ECR_REGISTRY}/${ECR_REPO}:nginx-${ENV}"
print_info "Next steps:"
echo "  1. Deploy to Kubernetes: ./scripts/deploy.sh ${ENV}"
echo "  2. Or manually: helm upgrade --install django-app charts/django-app -f charts/django-app/values-${ENV}.yaml"

