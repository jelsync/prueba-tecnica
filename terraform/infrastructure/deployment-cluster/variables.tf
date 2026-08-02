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

variable "shared_vpc_endpoints_sg_id" {
  description = "Security group de los VPC endpoints existentes (SSM/ECR/STS/...) al que hay que darle acceso desde los nodos EKS. Ver network.auto.tfvars."
  type        = string
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

variable "ecr_repository_name" {
  type    = string
  default = "labeks-microservice"
}

variable "development_cluster_name" {
  description = "Nombre del clúster development (debe coincidir con cluster_name en environments/development/terraform.tfvars) — solo para construir su ARN, no crea nada ahí."
  type        = string
  default     = "labeks-development-dev"
}

variable "tags" {
  type = map(string)
  default = {
    Project   = "labeks-devops-2026"
    Cluster   = "deployment"
    ManagedBy = "terraform"
  }
}
