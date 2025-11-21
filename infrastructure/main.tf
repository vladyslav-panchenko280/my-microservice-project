data "aws_eks_cluster" "eks" {
  name = var.cluster_name

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name

  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
  vpc_name           = var.vpc_name
  single_nat_gateway = var.single_nat_gateway
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = var.ecr_name
  scan_on_push = var.scan_on_push
  environment  = var.environment
  tags         = var.tags
}

module "eks" {
  source        = "./modules/eks"
  cluster_name  = var.cluster_name
  subnet_ids    = module.vpc.private_subnet_ids
  instance_type = var.instance_type
  desired_size  = var.desired_size
  max_size      = var.max_size
  min_size      = var.min_size
}

module "jenkins" {
  source                 = "./modules/jenkins"
  cluster_name           = var.cluster_name
  environment            = var.environment
  oidc_provider_arn      = module.eks.oidc_provider_arn
  oidc_provider_url      = module.eks.oidc_provider_url
  github_username        = var.jenkins_github_username
  github_token           = var.jenkins_github_token
  jenkins_admin_password = var.jenkins_admin_password
  aws_account_id         = var.aws_account_id

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "argocd" {
  source                = "./modules/argocd"
  cluster_name          = var.cluster_name
  environment           = var.environment
  oidc_provider_arn     = module.eks.oidc_provider_arn
  oidc_provider_url     = module.eks.oidc_provider_url
  github_username       = var.argocd_github_username
  github_token          = var.argocd_github_token
  git_repository_url    = var.argocd_git_repository_url
  argocd_admin_password = var.argocd_admin_password

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}

module "rds" {
  source = "./modules/rds"

  name                  = "myapp-db"
  use_aurora            = true
  aurora_instance_count = 2

  engine_cluster                = "aurora-postgresql"
  engine_version_cluster        = "15.4"
  parameter_group_family_aurora = "aurora-postgresql15"

  engine                     = "postgres"
  engine_version             = "17.2"
  parameter_group_family_rds = "postgres17"

  instance_class          = "db.r6g.large"
  allocated_storage       = 20
  db_name                 = "myapp"
  username                = var.db_username
  password                = var.db_password
  subnet_private_ids      = module.vpc.private_subnet_ids
  subnet_public_ids       = module.vpc.public_subnet_ids
  publicly_accessible     = false
  vpc_id                  = module.vpc.vpc_id
  multi_az                = true
  backup_retention_period = 7
  tags                    = var.tags
  parameters = {
    log_min_duration_statement = "500"
  }
}

resource "kubernetes_secret" "django_db" {
  metadata {
    name      = "django-db-credentials"
    namespace = "default"
  }

  data = {
    DB_HOST     = module.rds.db_host
    DB_PORT     = tostring(module.rds.db_port)
    DB_NAME     = module.rds.db_name
    DB_USER     = module.rds.db_username
    DB_PASSWORD = module.rds.db_password
  }

  type = "Opaque"

  depends_on = [module.eks]
}
