module "network" {
  source = "../../modules/existing-network"

  vpc_id             = var.existing_vpc_id
  public_subnet_ids  = var.existing_public_subnet_ids
  private_subnet_ids = var.existing_private_subnet_ids
}

module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name             = var.cluster_name
  kubernetes_version       = var.kubernetes_version
  control_plane_subnet_ids = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
  node_subnet_ids          = module.network.private_subnet_ids
  node_instance_types      = var.node_instance_types
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
  tags                     = var.tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name          = var.ecr_repository_name
  oidc_provider_arn        = module.eks.oidc_provider_arn
  oidc_provider_url        = module.eks.oidc_provider_url
  k8s_namespace            = "jenkins"
  k8s_service_account_name = "jenkins-ecr-push"
  tags                     = var.tags
}

module "alb_controller_irsa" {
  source = "../../modules/aws-load-balancer-controller-irsa"

  role_name         = "labeks-deployment-aws-load-balancer-controller"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = var.tags
}
