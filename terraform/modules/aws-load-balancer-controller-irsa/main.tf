# Rol IRSA para el AWS Load Balancer Controller del clúster development —
# necesario porque el Service del microservicio (y el de Vault) fijan sus
# subredes por anotación en vez de por tags (ver k8s/*/service*.yaml); el
# proveedor in-tree legacy de EKS no soporta eso, hace falta este controller.
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "labeks-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Política oficial del proyecto (docs/install/iam_policy.json en el repo de
# kubernetes-sigs/aws-load-balancer-controller), descargada tal cual — no
# transcrita de memoria.
resource "aws_iam_role_policy" "this" {
  name   = "aws-load-balancer-controller"
  role   = aws_iam_role.this.id
  policy = file("${path.module}/iam-policy.json")
}
