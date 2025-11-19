# Jenkins Helm Chart

This chart deploys Jenkins CI/CD server to Kubernetes with environment-specific configurations.

## Environments

This chart supports three environments:
- **dev**: Development environment with basic configuration
- **stag**: Staging environment with enhanced resources
- **prod**: Production environment with maximum resources and security

## Installation

The chart is deployed via Terraform. See the Jenkins module in `infrastructure/modules/jenkins/`.

## Environment-Specific Values

Each environment has its own values file:
- `values-dev.yaml`: Development configuration
- `values-stage.yaml`: Staging configuration
- `values-prod.yaml`: Production configuration

## Features

- Jenkins Configuration as Code (JCasC)
- Kubernetes cloud integration for dynamic agents
- Persistent storage with AWS EBS
- IAM roles for service accounts (IRSA) for ECR access
- Environment-specific job configurations
- GitHub integration

## Security Notes

For staging and production environments:
1. Create a Kubernetes secret for admin credentials:
   ```bash
   kubectl create secret generic jenkins-admin-secret \
     --from-literal=jenkins-admin-user=admin \
     --from-literal=jenkins-admin-password=<secure-password> \
     -n jenkins
   ```

2. Store GitHub credentials in AWS Secrets Manager or similar and reference them in JCasC.

## Accessing Jenkins

After deployment, Jenkins will be available via LoadBalancer service. Get the external IP:

```bash
kubectl get svc -n jenkins
```
