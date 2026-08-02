output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Subredes públicas usadas para el Load Balancer (anotarlas en el Service de k8s)."
  value       = module.network.public_subnet_ids
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_push_role_arn" {
  description = "Anotar en k8s/deployment-cluster/jenkins/build-agent-serviceaccount.yaml (eks.amazonaws.com/role-arn)."
  value       = module.ecr.push_role_arn
}

output "jenkins_deploy_role_arn" {
  description = "Anotar en k8s/deployment-cluster/jenkins/deploy-agent-serviceaccount.yaml (eks.amazonaws.com/role-arn)."
  value       = aws_iam_role.jenkins_deploy.arn
}

output "ebs_csi_driver_role_arn" {
  description = "Pasar como controller.serviceAccount.annotations al instalar el chart aws-ebs-csi-driver."
  value       = aws_iam_role.ebs_csi_driver.arn
}
