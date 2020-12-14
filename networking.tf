###VPC###
resource "aws_vpc" "k8s-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubernetes-the-hard-way"
  }
}
###SUBNET###
resource "aws_subnet" "kubernetes" {
  vpc_id     = aws_vpc.k8s-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "kubernetes"
  }
}
###INTERNET GATEWAY###
resource "aws_internet_gateway" "k8s_gw" {
  vpc_id = aws_vpc.k8s-vpc.id

  tags = {
    Name = "kubernetes"
  }
}
###ROUTE TABLES###
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_gw.id
  }

  tags = {
    Name = "kubernetes"
  }
}
###SECURITY GROUPS###
resource "aws_security_group" "k8s_sg" {
  name        = "kubernetes"
  description = "Kubernetes security group"
  vpc_id      = aws_vpc.k8s-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.200.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
###NETWORK LOAD BALANCER###
resource "aws_lb" "k8s_elbv2" {
  name               = "kubernetes"
  subnets            = [aws_subnet.kubernetes.id]
  load_balancer_type = "network"
  internal           = false

  provisioner "local-exec" {
    working_dir = "./certs"
    command     = "./gencerts.sh ${self.dns_name}"
  }
}
##TARGET GROUP##
resource "aws_lb_target_group" "k8s_tg" {
  name        = "kubernetes"
  protocol    = "TCP"
  port        = 6443
  vpc_id      = aws_vpc.k8s-vpc.id
  target_type = "ip"
}
resource "aws_lb_target_group_attachment" "k8s_tg_att1" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = "10.0.1.10"
}
resource "aws_lb_target_group_attachment" "k8s_tg_att2" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = "10.0.1.11"
}
resource "aws_lb_target_group_attachment" "k8s_tg_att3" {
  target_group_arn = aws_lb_target_group.k8s_tg.arn
  target_id        = "10.0.1.12"
}
resource "aws_lb_listener" "k8s_listener" {
  load_balancer_arn = aws_lb.k8s_elbv2.arn
  protocol          = "TCP"
  port              = "443"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
}
