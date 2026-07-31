variable "vpc_id" {
  description = "ID de la VPC ya existente en la que se despliega (no la crea ni la modifica este módulo)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subredes ya existentes con ruta directa a un Internet Gateway, para las ENIs del Load Balancer del microservicio."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subredes ya existentes donde corren los nodos EKS y sus pods."
  type        = list(string)
}
