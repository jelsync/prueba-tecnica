# El chart aws-ebs-csi-driver necesita este rol para crear/adjuntar/
# desmontar volúmenes EBS reales -- sin él, los PVC de Vault y Jenkins se
# quedan en Pending para siempre (confirmado en vivo: "pod has unbound
# immediate PersistentVolumeClaims", 0/2 nodes available). Solo hace falta
# en este clúster: development no usa almacenamiento persistente.
data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = "labeks-deployment-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
  tags               = var.tags
}

# Política oficial administrada por AWS -- no hace falta escribir permisos
# de EBS a mano.
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# AmazonEBSCSIDriverPolicy NO incluye ningún permiso de kms:* (confirmado
# leyendo el policy document oficial de AWS). Como el cifrado de EBS por
# defecto está activo en la cuenta, CreateVolume "acepta" la solicitud pero
# nunca termina de materializar el volumen sin poder usar la key -- por eso
# DescribeVolumes nunca lo encontraba (diagnosticado en vivo, con varios
# intentos y volúmenes distintos cada vez, todos con el mismo resultado).
# data source en vez de un ARN a mano: no hace falta versionar el key id
# real de la cuenta.
data "aws_ebs_default_kms_key" "current" {}

data "aws_iam_policy_document" "ebs_csi_kms" {
  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:ReEncrypt*",
    ]
    resources = [data.aws_ebs_default_kms_key.current.key_arn]
  }
}

resource "aws_iam_role_policy" "ebs_csi_driver_kms" {
  name   = "ebs-csi-driver-kms"
  role   = aws_iam_role.ebs_csi_driver.id
  policy = data.aws_iam_policy_document.ebs_csi_kms.json
}
