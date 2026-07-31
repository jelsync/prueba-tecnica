# Este módulo NUNCA crea, modifica ni importa recursos de red: solo los lee vía
# data sources para que eks-cluster sepa dónde desplegarse. Se usa en cuentas de
# AWS donde ya existe otra infraestructura que no se debe tocar — la VPC, sus
# subredes, route tables e Internet Gateway quedan exactamente como están.
data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}
