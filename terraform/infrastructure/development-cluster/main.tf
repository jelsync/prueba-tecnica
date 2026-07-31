module "networking" {
  source = "../../modules/networking"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = merge(var.tags, { Environment = var.environment })
}

module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name             = var.cluster_name
  kubernetes_version       = var.kubernetes_version
  control_plane_subnet_ids = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  node_subnet_ids          = module.networking.private_subnet_ids
  node_instance_types      = var.node_instance_types
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
  tags                     = merge(var.tags, { Environment = var.environment })
}
