resource "aws_vpc_security_group_ingress_rule" "eks_nodes_to_shared_vpc_endpoints" {
  security_group_id            = var.shared_vpc_endpoints_sg_id
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: nodos EKS del laboratorio personal (temporal, revertir despues de probar)"
}
