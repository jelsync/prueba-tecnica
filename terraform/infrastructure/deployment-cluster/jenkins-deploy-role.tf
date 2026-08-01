# Rol IRSA para el pod agente de Jenkins que hace el deploy al clúster
# development — separado del rol de push a ECR (module.ecr) por mínimo
# privilegio: este no toca ECR, el otro no toca la API de Kubernetes de otro
# clúster. El acceso real dentro de k8s (qué puede hacer una vez
# autenticado) lo define el Access Entry en development-cluster, no este rol.
data "aws_caller_identity" "current" {}

locals {
  # Mismo patrón que el ARN del cluster: se calcula, nunca se pega a mano ni
  # se versiona el account id en un tfvars.
  development_cluster_arn = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.development_cluster_name}"
}

data "aws_iam_policy_document" "jenkins_deploy_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:jenkins:jenkins-deploy"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_deploy" {
  name               = "labeks-jenkins-deploy"
  assume_role_policy = data.aws_iam_policy_document.jenkins_deploy_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "jenkins_deploy_permissions" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = [local.development_cluster_arn]
  }
}

resource "aws_iam_role_policy" "jenkins_deploy" {
  name   = "eks-describe-development"
  role   = aws_iam_role.jenkins_deploy.id
  policy = data.aws_iam_policy_document.jenkins_deploy_permissions.json
}
