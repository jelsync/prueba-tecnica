output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  value = aws_ecr_repository.this.arn
}

output "push_role_arn" {
  description = "ARN a anotar en el ServiceAccount de k8s del agente de build (eks.amazonaws.com/role-arn)."
  value       = aws_iam_role.push.arn
}
