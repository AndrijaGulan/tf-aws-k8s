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

###K8S CONTROLLERS###
resource "aws_instance" "controller" {
  for_each      = toset(["0", "1", "2"])
  ami           = data.aws_ami.ubuntu20.id
  instance_type = "t3.micro"
  key_name      = "kubernetes"

  private_ip                  = "10.0.1.1${each.key}"
  subnet_id                   = aws_subnet.kubernetes.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "controller-${each.key}"
  }
}
resource "aws_instance" "worker" {
  for_each      = toset(["0", "1", "2"])
  ami           = data.aws_ami.ubuntu20.id
  instance_type = "t3.micro"
  key_name      = "kubernetes"

  private_ip                  = "10.0.1.2${each.key}"
  subnet_id                   = aws_subnet.kubernetes.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name    = "worker-${each.key}"
    PodCidr = "10.200.${each.key}.0/24"
  }
}
