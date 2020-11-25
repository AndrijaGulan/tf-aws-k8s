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

resource "aws_key_pair" "k8s_key" {
  key_name   = "kubernetes"
  public_key = "-----BEGIN RSA PRIVATE KEY-----MIIEpAIBAAKCAQEAupK8yk+5QogFHOn3Ilp3nHBkNxuRkJtJk8+wRwxPBI9A3lB5/JANfw4+LmQaaAGHaUr6pdUEQxypuEhEE98LJnA2fkNk4ag1RpvVjLsweWVm9WZ0N3xak8AIAV3nMgrA2kY7IXK/jyyngpGRGy/XBMAhACAdcm69t3ZbznLeFlJVbxCy55tZeeQjtiM0tcGT+QI9SLuB4cB6tgc/EpOAQfUjoN4UudKNYdOEcVMbEYiy91L5yYcH2PjSEz2iKIDyXCl+0L8QiXW9oSbLSS5p/g3Qhw6Pc5URTsdigAPBBwXFb91JONbKjTn6cJ3XnqzaMNYhYG2/9UVd99ziCNIwhQIDAQABAoIBAEY3nZfio0231XzJTTp/o86bugvHc2RiHTHlE2nZ5w9HPtmsngyAxqOP37Uj9ZA5KxZkoqqw3fbIHdP+VqjH4/FmgAvLH3eSD+LwGVHqzVaS5EntckXDpm8+8YRaK/34cBZ2IiD3h8LBwpVwZZU+zwS5rnHWpF6B8SLQB8NOFel+ErgVkxrtfU7ZUScsVS6pW41xzeI/MmuNH1Et4U5IVINH8o16hvhi8LuawuNVvooeO5CcYImNkyB4FQiuVNs2qMIIX0ghqNR+Jrm5ANVZYf8b0n2upMA1gebtHUYKfma5Gzvd5t0BbznUuzxrlFLIAyou2rzTY2vC/t08oarDO60CgYEA/tl7HaHsKigasOnIbwyO6dqUwbNfygaL+s4z6DmjT/RPQc6pK+eLPLfrEmIO+wBvqR9COmZnN0ajN0Nf1zb8ihtSy24gQKJ+oCISeeJF+N4z/UzS1K5EaJgExr1Z0gl2gclO3qacx71C0u/MShydQrrsINPvaWTQE2XkPel1x58CgYEAu2paNnmQK3HPbUAwwQAzO7AAPVGc+ZRHeVUdfiQTgByyCal3zEeiwOhlMmyr2D63WpWhKRv20hjNt3NH/GTivjSkU+nJqEifS6nyodDAZ/xYjs2oB+DjvWUY8IZVJxOmw1BGC7e+b206zfDHlMUIm2m6lLlPHwOOzpRNKLC95VsCgYEAkCHd4Hd4gqsl1VKS+kNG/HmT0i0piq/DMTi34KngdFK/FH/V66/Lbq6x8zakNE8d16+HHFJYI8n+ez3OkYBWuaEUZVtGQGfmZ5h9jJNtcX/yNVrijkh1Bhab9O6YQxL5BBQfWAsw9kJS7cuTZYLjah8fdr2GVLwgdigVOvKzmw8CgYBsDahPigzmD2sRSRYS4GOpgRLSR7CicKw4tysW5APeNC0txuhL/e1HHXXi+aamOZqK/oP5aKcIgMZyg2O4kA3urfkkbEEY5i35eNVsGCgmi+YfB1FeoXmMY7JaUojby8e1Ch4oeVqxcZ+axry6+FK7D91EDAcjEXEPh49o62XAywKBgQC5ssVFo9Rf2+nIvjgxZsBjxx7X4u3/cTmsW5AEUUE7wa8yR76TF9ytugHLbmNrEPJZ/4s+CbbdjKv28tMLfX6J5PJ3lyiDF0vWNCwz+mMJCHjaKana9/eWHnyObHR6f/tEBX61gLX2vi75Rwpy6l7ekooYnE4YEJr6HcEayfWXbw==-----END RSA PRIVATE KEY-----"
}

###K8S CONTROLLERS###
resource "aws_instance" "controller" {
  for_each      = toset(["0", "1", "2"])
  ami           = data.aws_ami.ubuntu20.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.k8s_key.key_name

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
  key_name      = aws_key_pair.k8s_key.key_name

  private_ip                  = "10.0.1.2${each.key}"
  subnet_id                   = aws_subnet.kubernetes.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  associate_public_ip_address = true
  tags = {
    Name    = "worker-${each.key}"
    PodCidr = "10.200.${each.key}.0/24"
  }
}