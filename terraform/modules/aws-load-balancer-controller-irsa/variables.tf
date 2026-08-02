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
