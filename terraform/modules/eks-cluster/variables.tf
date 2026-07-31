variable "cluster_name" {
  description = "Nombre del clúster EKS."
  type        = string
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes para el control plane."
  type        = string
  default     = "1.31"
}

variable "control_plane_subnet_ids" {
  description = "Subredes (públicas + privadas) donde EKS coloca las ENIs del control plane."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subredes privadas donde corren los nodos worker."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Tipos de instancia EC2 para el node group administrado."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "AMI type del node group administrado."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
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
  default = 4
}

variable "endpoint_public_access" {
  description = "Si el endpoint de la API de Kubernetes es accesible públicamente. En un laboratorio se deja en true por simplicidad de acceso desde kubectl local."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
