terraform {
  backend "s3" {
    # Backend configuration is provided via backend config file or CLI
    # Use: terraform init -backend-config=environments/<env>/backend.hcl
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

