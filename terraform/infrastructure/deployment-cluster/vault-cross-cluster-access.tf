# El pod de Vault corre en un nodo del clúster deployment, protegido por SU
# security group -- por defecto, el security group que EKS crea para un
# clúster solo permite tráfico desde sí mismo, no desde el de OTRO clúster.
# Sin esto, el clúster development (VSO) no puede alcanzar el Load Balancer
# interno de Vault -- confirmado en vivo: "Failed to check Vault seal
# status... error=context deadline exceeded". A diferencia de los VPC
# endpoints compartidos, este security group SÍ es nuestro (lo creó nuestro
# propio clúster deployment), así que es una regla aditiva sobre un recurso
# que ya administramos, no algo ajeno.
#
# El puerto real NO es 8200: el Service es type=LoadBalancer con target
# type "instance" (confirmado con describe-target-health: puerto 31814),
# así que el NLB reenvía al NodePort real, no al puerto lógico del Service.
# Como Kubernetes asigna el NodePort dinámicamente, se abre el rango
# completo de NodePort (30000-32767) en vez de un puerto fijo que podría
# cambiar si el Service se recrea.
resource "aws_vpc_security_group_ingress_rule" "vault_from_development" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = data.aws_eks_cluster.development.vpc_config[0].cluster_security_group_id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster development necesita llegar al NodePort de Vault (VSO)"
}
