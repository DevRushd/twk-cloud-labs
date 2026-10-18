data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical, Ubuntu publisher

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "twk-kp" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key

  tags = var.tags
}

resource "aws_instance" "dev" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.dev.id
  vpc_security_group_ids      = [aws_security_group.dev-sg.id]
  key_name                    = aws_key_pair.twk-kp.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.system_disk_size
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_type           = "gp3"
    volume_size           = var.data_disk_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(var.tags, {
    Name = var.instance_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip" "dev" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-dev-eip"
  })
}

resource "aws_eip_association" "dev" {
  allocation_id = aws_eip.dev.id
  instance_id   = aws_instance.dev.id
}
