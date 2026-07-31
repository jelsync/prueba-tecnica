variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "labeks-deployment"
}

# Sin default a propósito: los IDs reales de la VPC/subredes existentes no se
# versionan (ver .gitignore) y se pasan vía environments/deployment/network.auto.tfvars.
variable "existing_vpc_id" {
  description = "VPC ya existente en la cuenta donde se despliega este clúster."
  type        = string
}

variable "existing_public_subnet_ids" {
  description = "Subredes existentes con ruta directa a un Internet Gateway (para el Load Balancer)."
  type        = list(string)
}

variable "existing_private_subnet_ids" {
  description = "Subredes existentes donde corren los nodos EKS."
  type        = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "labeks-devops-2026"
    Cluster   = "deployment"
    ManagedBy = "terraform"
  }
}
