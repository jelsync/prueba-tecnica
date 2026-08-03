data "aws_eks_cluster" "deployment" {
  name = var.deployment_cluster_name
}

resource "aws_vpc_security_group_ingress_rule" "eks_api_from_deployment" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = data.aws_eks_cluster.deployment.vpc_config[0].cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster deployment (Jenkins) necesita llegar a la API de este cluster"
}
