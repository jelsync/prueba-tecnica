# El pod de Vault corre en un nodo del clúster deployment, protegido por SU
# security group -- por defecto, el security group que EKS crea para un
# clúster solo permite tráfico desde sí mismo, no desde el de OTRO clúster.
# Sin esto, el clúster development (VSO) no puede alcanzar el Load Balancer
# interno de Vault en el puerto 8200 -- confirmado en vivo: "Failed to check
# Vault seal status... error=context deadline exceeded". A diferencia de
# los VPC endpoints compartidos, este security group SÍ es nuestro (lo creó
# nuestro propio clúster deployment), así que es una regla aditiva sobre
# un recurso que ya administramos, no algo ajeno.
resource "aws_vpc_security_group_ingress_rule" "vault_from_development" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = data.aws_eks_cluster.development.vpc_config[0].cluster_security_group_id
  from_port                    = 8200
  to_port                      = 8200
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster development necesita llegar a Vault (VSO)"
}
