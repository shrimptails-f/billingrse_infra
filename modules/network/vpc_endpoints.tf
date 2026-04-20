resource "aws_security_group" "vpce" {
  name        = "${local.deploy_name}-vpce"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "vpce_from_vpc_https" {
  security_group_id            = aws_security_group.vpce.id
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_db["a"].id]
  security_group_ids  = [aws_security_group.vpce.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-vpce-ecr-api"
    },
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_db["a"].id]
  security_group_ids  = [aws_security_group.vpce.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-vpce-ecr-dkr"
    },
  )
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_db["a"].id]
  security_group_ids  = [aws_security_group.vpce.id]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-vpce-logs"
    },
  )
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_db.id,
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-vpce-s3"
    },
  )
}
