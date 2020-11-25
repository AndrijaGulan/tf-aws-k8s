provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu20" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
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

resource "aws_key_pair" "k8s_key" {
  key_name   = "kubernetes"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLzwArEhK0Gb+dwvb0/BhL7yqAtm6dVCutTx3JoIbK2oRk6xJzMTtgqN+IUK/01KGD8CZLIDn851fizaSbAf9PCrcpxbFWr3nuu88tUIK7Len3KP9mL8ba3AkNzZGWTNcr2ldm7tbzaNwa1Z2Twk69oPik32i5u2Z4t4lKZKd6K0m/ChB3CFuS/8It7BpipyCNEjZUykhIbqg91xerMPFpgjJKc8GmoYs9KAC9SsLmbYL/yjUJCAWoY57RHehx6bzUfT3nbV3b9ptbLeCe6ubvdBQG0NMD+nnqJdKD9TXnYaLkRQEqySRFnGcjYjFiZgTB743PSxUfVE3Uq6/pcQfhxSrjVu4FXIENj76CrzZGCCJQND+0gfJTSToKYCAoT/dJU/ywYOTo/NLsAPb3to/Habl5PztM/Jwim7CYlc3hlwErbda7kBhsu8l43XAYA7T5g7MHoR//oaIskDmba4uZpVSJvhcXz0/cmbGy2tthOs8ttewX89sVGQ5HsmGSwAue+nYrcbqCN7qAAxY6z2Os1DQX5Y8FhPZXPp0c4SoARfDGnCfVEELe2zgo6ERvoQgx2C6QHYGRpXKSyEYV2xOJHjQvGyoZsgV2CTZvjfX2UPdUwsdh0vTj997keY2YLLcrzmIZa1mhRZPpnZ96NTqi5zTfNXjpTxMKNXzs4qCPYQ== andrija@united.rs"
}

###K8S CONTROLLERS###
resource "aws_instance" "controller" {
  for_each      = toset(["0", "1", "2"])
  ami           = data.aws_ami.ubuntu20.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.k8s_key.key_name

  private_ip             = "10.0.1.1${each.key}"
  subnet_id              = aws_subnet.kubernetes.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip    = true
  tags = {
    Name = "controller-${each.key}"
  }
}
resource "aws_instance" "worker" {
  for_each      = toset(["0", "1", "2"])
  ami           = data.aws_ami.ubuntu20.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.k8s_key.key_name

  private_ip             = "10.0.1.2${each.key}"
  subnet_id              = aws_subnet.kubernetes.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  associate_public_ip    = true
  tags = {
    Name    = "worker-${each.key}"
    PodCidr = "10.200.${each.key}.0/24"
  }
}
