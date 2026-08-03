data "aws_caller_identity" "current" {}

locals {
  jenkins_deploy_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/labeks-jenkins-deploy"
}

resource "aws_eks_access_entry" "jenkins_deploy" {
  cluster_name  = module.eks.cluster_name
  principal_arn = local.jenkins_deploy_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "jenkins_deploy_edit" {
  cluster_name  = module.eks.cluster_name
  principal_arn = local.jenkins_deploy_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["development"]
  }

  depends_on = [aws_eks_access_entry.jenkins_deploy]
}
