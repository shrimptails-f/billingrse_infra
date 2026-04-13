# Public subnets
resource "aws_subnet" "public" {
  for_each = var.public_subnet_cidrs

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-public-${each.key}"
    },
  )
}

# Private db subnets
resource "aws_subnet" "private_db" {
  for_each = var.private_db_subnet_cidrs

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "${var.aws_region}${each.key}"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.deploy_name}-private-db-${each.key}"
    },
  )
}
