# Los VPC endpoints de la VPC compartida (SSM, ECR, STS, logs, etc. —
# confirmado que TODOS usan el mismo security group) solo aceptan HTTPS
# desde los security groups de los workloads ya existentes (bastion, ECS,
# ALB). Sin esto los nodos EKS no llegan a ECR/STS/SSM y nunca terminan de
# arrancar (NodeCreationFailure: Unhealthy nodes — diagnosticado en vivo
# contra la cuenta real).
#
# Esto agrega UNA regla de entrada nueva al SG compartido -- no toca, borra
# ni reemplaza ninguna de las reglas existentes (bastion/ECS/ALB siguen
# igual). Mismo patrón que ya usaron para darle acceso a esos tres.
#
# Temporal, a propósito: el usuario decidió borrar o acotar esto una vez
# termine de probar el laboratorio (ver README).
resource "aws_vpc_security_group_ingress_rule" "eks_nodes_to_shared_vpc_endpoints" {
  security_group_id            = var.shared_vpc_endpoints_sg_id
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: nodos EKS del laboratorio personal (temporal, revertir despues de probar)"
}
