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
