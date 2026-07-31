output "vpc_id" {
  value = data.aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas existentes (para las ENIs del Load Balancer)."
  value       = [for s in data.aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas existentes (para los nodos EKS)."
  value       = [for s in data.aws_subnet.private : s.id]
}

output "private_subnet_azs" {
  value = [for s in data.aws_subnet.private : s.availability_zone]
}
