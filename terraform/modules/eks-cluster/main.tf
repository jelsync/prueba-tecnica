data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.control_plane_subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  # Sin esto, el default es CONFIG_MAP (legacy) y los EKS Access Entries
  # (los que usa development-cluster para el rol de deploy de Jenkins) no se
  # pueden crear -- encontrado en vivo al aplicar development-cluster.
  #
  # bootstrap_cluster_creator_admin_permissions se fija explícitamente en
  # true porque así quedó ya en el clúster existente (default de AWS al
  # crearlo) -- omitirlo hace que Terraform lo interprete como "cambiar a
  # null", y ese campo específico SÍ fuerza a reemplazar el clúster entero
  # (visto en un "terraform plan" real antes de aplicar, por suerte).
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

# OIDC provider: habilita IRSA, requerido por Vault Secrets Operator y el Vault CSI provider
# para asumir roles de IAM sin credenciales estáticas.
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = var.tags
}

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# La AMI EKS-optimizada de Amazon Linux 2023 trae su snapshot raíz SIN
# cifrar (confirmado con `aws ec2 describe-images`: "Encrypted": false). Al
# lanzar la instancia, EC2 tiene que re-cifrarla sobre la marcha usando la
# key de cifrado-por-defecto de la cuenta -- y esa key/flujo dio
# "Client.InvalidKMSKey.InvalidState" de forma repetible (2 intentos, cada
# uno con instancias nuevas). Se usa una key propia del laboratorio en vez
# de depender de la de la cuenta, fijada explícitamente en un launch
# template -- así no importa qué esté mal con la key por defecto.
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "node_ebs" {
  description             = "Cifra los volumenes EBS de los nodos de ${var.cluster_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "node_ebs" {
  name          = "alias/${var.cluster_name}-node-ebs"
  target_key_id = aws_kms_key.node_ebs.key_id
}

data "aws_iam_policy_document" "node_ebs_key" {
  statement {
    sid       = "EnableRootAccess"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowEC2AndAutoscalingReencrypt"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "ec2.${data.aws_region.current.name}.amazonaws.com",
        "autoscaling.${data.aws_region.current.name}.amazonaws.com",
      ]
    }
  }
}

resource "aws_kms_key_policy" "node_ebs" {
  key_id = aws_kms_key.node_ebs.id
  policy = data.aws_iam_policy_document.node_ebs_key.json
}

resource "aws_launch_template" "node" {
  name_prefix = "${var.cluster_name}-node-"

  # Sin image_id/user_data: EKS los completa automáticamente para el
  # ami_type configurado en el node group (AL2023_x86_64_STANDARD). Solo se
  # sobreescribe el volumen raíz para forzar nuestra propia KMS key.
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.node_ebs.arn
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  tags = var.tags
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-default"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.node_subnet_ids
  instance_types  = var.node_instance_types
  ami_type        = var.node_ami_type

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_readonly,
  ]
}
