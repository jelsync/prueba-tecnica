# Mismo problema que en deployment-cluster (mismas subredes, mismos VPC
# endpoints compartidos): sin esto los nodos de este clúster tampoco
# arrancarían. Ver deployment-cluster/allow-node-to-vpc-endpoints.tf para el
# diagnóstico completo. Solo agrega una regla de entrada nueva -- no toca
# ninguna existente.
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_to_shared_vpc_endpoints" {
  security_group_id            = var.shared_vpc_endpoints_sg_id
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: nodos EKS del laboratorio personal (temporal, revertir despues de probar)"
}
