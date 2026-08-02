output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  description = "ARN del proveedor OIDC del clúster; se usa para las IAM roles con IRSA que asumirá Vault Secrets Operator o el CSI provider."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  value = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "node_ebs_kms_key_arn" {
  description = "Key propia usada para cifrar los volúmenes EBS de los nodos (no la default de la cuenta)."
  value       = aws_kms_key.node_ebs.arn
}

output "cluster_security_group_id" {
  description = "Security group que EKS crea automáticamente para el clúster/nodos (no lo creamos nosotros, lo expone el propio recurso)."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
