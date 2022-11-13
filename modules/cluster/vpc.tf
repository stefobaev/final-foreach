resource "aws_vpc" "main" {
  cidr_block = var.cidr_block_vpc

  tags = {
    Name = "VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = each.value["tags"]
}

resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = each.value["tags"]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name = "NAT Gateway EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet["Public1"].id

  tags = {
    Name = "NAT Gateway"
  }
  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_route_table" "public" {
  for_each = var.PublicRouteTable
  vpc_id   = aws_vpc.main.id

  dynamic "route" {
    for_each = var.PublicRouteTable
    content {
      cidr_block = var.cidr_block
      gateway_id = aws_internet_gateway.igw.id
    }
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet["Public1"].id
  route_table_id = aws_route_table.public["Public1"].id

}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public_subnet["Public2"].id
  route_table_id = aws_route_table.public["Public2"].id

}

resource "aws_route_table" "private" {
  for_each = var.PrivateRouteTable
  vpc_id   = aws_vpc.main.id

  dynamic "route" {
    for_each = var.PrivateRouteTable
    content {
      cidr_block = var.cidr_block
      nat_gateway_id = aws_nat_gateway.nat.id
    }
  }

  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "private" {

  subnet_id      = aws_subnet.private_subnet["Private1"].id
  route_table_id = aws_route_table.private["Private1"].id
}

resource "aws_route_table_association" "private2" {

  subnet_id      = aws_subnet.private_subnet["Private2"].id
  route_table_id = aws_route_table.private["Private2"].id
}