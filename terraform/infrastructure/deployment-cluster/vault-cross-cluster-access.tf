resource "aws_vpc_security_group_ingress_rule" "vault_from_development" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = data.aws_eks_cluster.development.vpc_config[0].cluster_security_group_id
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster development necesita llegar al NodePort de Vault (VSO)"
}
