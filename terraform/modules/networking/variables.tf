variable "cluster_name" {
  description = "Nombre del clúster EKS que consumirá esta red; se usa en las etiquetas de descubrimiento de subredes (kubernetes.io/cluster/<name>)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones donde se crean las subredes públicas y privadas."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs de las subredes públicas (una por AZ, mismo orden que var.azs)."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas donde corren los nodos EKS (una por AZ, mismo orden que var.azs)."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true crea un solo NAT Gateway compartido (más barato, recomendado para dev/qa). false crea un NAT Gateway por AZ (mayor disponibilidad, recomendado para prod)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes a propagar a todos los recursos de red."
  type        = map(string)
  default     = {}
}
