# La VPC compartida no tiene un VPC endpoint para "ec2" (solo "ec2messages",
# que es para SSM, no la API principal de EC2) -- confirmado en vivo: el EBS
# CSI driver crea el volumen pero el DescribeVolumes inmediato despues no lo
# encuentra, de forma repetida con volumenes distintos cada vez. Las
# llamadas a la API de EC2 salen por el Transit Gateway compartido en vez
# de la red privada de AWS. Se crea un VPC endpoint nuevo (no se toca
# ninguno existente) con su propio security group.
#
# Se deja abierto también para el clúster development: el AWS Load Balancer
# Controller que corre ahí también llama a la API de EC2
# (DescribeSubnets/DescribeSecurityGroups/etc.) y muy probablemente
# tropezaría con lo mismo al crear el primer Load Balancer real.
data "aws_eks_cluster" "development" {
  name = var.development_cluster_name
}

resource "aws_security_group" "ec2_vpc_endpoint" {
  name        = "labeks-ec2-vpc-endpoint"
  description = "HTTPS desde los clusteres EKS del laboratorio hacia el VPC endpoint de EC2"
  vpc_id      = var.existing_vpc_id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "ec2_endpoint_from_deployment" {
  security_group_id            = aws_security_group.ec2_vpc_endpoint.id
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster deployment (EBS CSI driver)"
}

resource "aws_vpc_security_group_ingress_rule" "ec2_endpoint_from_development" {
  security_group_id            = aws_security_group.ec2_vpc_endpoint.id
  referenced_security_group_id = data.aws_eks_cluster.development.vpc_config[0].cluster_security_group_id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "labeks: cluster development (AWS Load Balancer Controller)"
}

resource "aws_vpc_security_group_egress_rule" "ec2_endpoint_all" {
  security_group_id = aws_security_group.ec2_vpc_endpoint.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.existing_vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.existing_private_subnet_ids
  security_group_ids  = [aws_security_group.ec2_vpc_endpoint.id]
  private_dns_enabled = true
  tags                = var.tags
}
