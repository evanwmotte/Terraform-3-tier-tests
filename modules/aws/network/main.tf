resource "aws_vpc" "three-tier-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "web-subnet" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "app-subnet" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.1.0/25"
  availability_zone = "us-east-2a"
}

resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.1.0/26"
  availability_zone = "us-east-2a"
}

resource "db_subnet" "db-subnet" {
  vpc_id            = aws_vpc.three-tier-vpc.id
  cidr_block        = "10.0.1.0/27"
  availability_zone = "us-east-2a"
}

resource "aws_internet_gateway" "three-tier-gateway" {
  vpc_id = aws_vpc.three-tier-vpc.id
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-gateway.id
  }
}

resource "aws_route_table_association" "public-route-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public-subnet.id
}

resource "aws_route_table" "web-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-gateway.id
  }
}

resource "aws_route_table_association" "web-route-table-association" {
  subnet_id      = aws_vpc.three-tier-vpc.id
  route_table_id = aws_route_table.web-route-table.id
}

resource "aws_route_table" "app-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-gateway.id
  }
}

resource "aws_route_table_association" "app-route-table-association" {
  subnet_id      = aws_vpc.three-tier-vpc.id
  route_table_id = aws_route_table.app-route-table.id
}

resource "aws_route_table" "db-route-table" {
  vpc_id = aws_vpc.three-tier-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.three-tier-gateway.id
  }
}

resource "aws_route_table_association" "db-route-table-association" {
  subnet_id      = aws_vpc.three-tier-vpc.id
  route_table_id = aws_route_table.db-route-table.id
}

resource "aws_lb" "web-lb" {
  name               = var.web-lb_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.webserver_sg.id]
  subnets            = [aws_subnet.web.*.id]

  tags {
    Name = var.lb_name
  }
}

resource "aws_lb_target_group" "alb_group" {
  name     = var.tg_name
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = aws_vpc.three-tier-vpc.id
}

resource "aws_lb_listener" "webserver-lb" {
  load_balancer_arn = aws_lb.web-lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    target_group_arn = aws_lb_target_group.alb_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_rule" "allow_all" {
  listener_arn = aws_lb_listener.webserver-lb.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_group.arn
  }

  condition {
    field  = "path-pattern"
    values = ["*"]
  }
}