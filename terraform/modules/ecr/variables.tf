variable "repository_name" {
  type    = string
  default = "labeks-microservice"
}

variable "oidc_provider_arn" {
  description = "ARN del proveedor OIDC del clúster deployment (para el rol IRSA que usa el agente de build de Jenkins)."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL del proveedor OIDC (sin https://), para la condición del trust policy."
  type        = string
}

variable "k8s_namespace" {
  description = "Namespace del ServiceAccount que puede asumir el rol de push a ECR."
  type        = string
  default     = "jenkins"
}

variable "k8s_service_account_name" {
  type    = string
  default = "jenkins-ecr-push"
}

variable "tags" {
  type    = map(string)
  default = {}
}
