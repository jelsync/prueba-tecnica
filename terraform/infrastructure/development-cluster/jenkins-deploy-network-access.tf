# El pod agente "jenkins-deploy" corre en un nodo del clúster deployment y
# necesita llamar a la API de ESTE clúster (kubectl set image / rollout) --
# por defecto, el security group que EKS crea para un clúster solo permite
# tráfico desde sí mismo, no desde el de OTRO clúster. Sin esto, "kubectl"
# se queda esperando y termina en timeout -- confirmado en vivo: "dial tcp
# 10.31.178.x:443: i/o timeout" contra el endpoint de la API (el nombre
# público resuelve a IPs privadas del VPC porque se consulta desde dentro
# de la VPC, así que el tráfico sí pasa por este security group).
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
