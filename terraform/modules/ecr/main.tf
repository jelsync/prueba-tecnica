resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  # Sin esto, "terraform destroy" falla si el pipeline ya subió alguna
  # imagen: ECR no deja borrar un repo con contenido salvo que se fuerce.
  # Este es un laboratorio de corta vida, no un registry de producción.
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expira imagenes sin tag despues de 7 dias"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 7
      }
      action = { type = "expire" }
    }]
  })
}

# IRSA: el ServiceAccount de k8s (usada por el pod agente de Jenkins que
# construye/publica la imagen) puede asumir este rol sin ninguna access key
# de AWS guardada en Jenkins.
data "aws_iam_policy_document" "push_assume_role" {
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

resource "aws_iam_role" "push" {
  name               = "${var.repository_name}-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.push_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "push_permissions" {
  statement {
    # GetAuthorizationToken no admite scoping por recurso (siempre "*" en la API de ECR).
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_role_policy" "push" {
  name   = "ecr-push"
  role   = aws_iam_role.push.id
  policy = data.aws_iam_policy_document.push_permissions.json
}
