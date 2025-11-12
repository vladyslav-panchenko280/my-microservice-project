# S3 backend is created manually outside of Terraform
# to avoid chicken-and-egg problem with state storage

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

