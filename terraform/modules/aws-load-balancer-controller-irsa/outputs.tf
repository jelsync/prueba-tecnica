output "role_arn" {
  description = "Anotar en k8s/development/aws-load-balancer-controller/values.yaml (serviceAccount.annotations)."
  value       = aws_iam_role.this.arn
}
