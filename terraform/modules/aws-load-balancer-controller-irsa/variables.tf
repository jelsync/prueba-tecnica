variable "role_name" {
  description = "Nombre del rol IAM. Debe ser distinto por clúster -- IAM no permite nombres de rol repetidos en la misma cuenta."
  type        = string
  default     = "labeks-aws-load-balancer-controller"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "k8s_namespace" {
  description = "Namespace donde el chart eks/aws-load-balancer-controller crea su ServiceAccount (kube-system por defecto en el chart)."
  type        = string
  default     = "kube-system"
}

variable "k8s_service_account_name" {
  type    = string
  default = "aws-load-balancer-controller"
}

variable "tags" {
  type    = map(string)
  default = {}
}
