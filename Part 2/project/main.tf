resource "aws_vpc" "staging_vpc" {
  cidr_block = "10.0.0.0/16"
  
tags = {
    Name = "Staging_vpc"
  }
}
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
 
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "private3" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "private4" {
  vpc_id            = aws_vpc.staging_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-1b"
}

resource "aws_internet_gateway" "Myigw" {
  vpc_id = aws_vpc.staging_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

resource "aws_nat_gateway" "Mynat" {
  allocation_id = aws_eip.Mynat-eip.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "MyNat"
  }
}

resource "aws_eip" "Mynat-eip" {
    domain = "vpc"
  
}

resource "aws_route_table" "Public-RT" {
  vpc_id = aws_vpc.staging_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Myigw.id
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.Public-RT.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.Public-RT.id
}

resource "aws_route_table" "private-RT" {
  vpc_id = aws_vpc.staging_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Mynat.id
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private3" {
  subnet_id      = aws_subnet.private3.id
  route_table_id = aws_route_table.private-RT.id
}

resource "aws_route_table_association" "private4" {
  subnet_id      = aws_subnet.private4.id
  route_table_id = aws_route_table.private-RT.id
}

#SECURITY GROUP---------------------------------------------------------------------------

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.staging_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "instance-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.staging_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  description = "Allow Prometheus and related services traffic"
  vpc_id      = aws_vpc.staging_vpc.id

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 9115
    to_port     = 9115
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# ec2 in private 2 and private 4
resource "aws_instance" "qa_instance" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private1.id
  security_groups = [aws_security_group.instance_sg.id]
  tags = {
    Name = "QA Instance"
  }
}

resource "aws_instance" "prometheus_server2" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private2.id
  security_groups = [aws_security_group.prometheus_sg.id]
  tags = {
    Name = "Prometheus Server2"
  }
}
resource "aws_instance" "prometheus_server4" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private4.id
  security_groups = [aws_security_group.prometheus_sg.id]
  tags = {
    Name = "Prometheus Server4"
  }
}
resource "aws_instance" "prometheus_server1" {
  ami           = var.ami
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private4.id
  security_groups = [aws_security_group.prometheus_sg.id]

  tags = {
    Name = "Prometheus Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y prometheus
              sudo service prometheus start
              EOF
}

# ALB -----------------------------------------------------------------------------------------------

resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.private2.id, aws_subnet.private4.id]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "main" {
  name        = "main-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.staging_vpc.id
  target_type = "instance"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.main.arn
}

#AUTO SCALING GROUP-------------------------------------------------------------
resource "aws_launch_configuration" "app" {
  name          = "app-lc"
  image_id      = var.ami
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private2.id, aws_subnet.private4.id]
  target_group_arns    = [aws_lb_target_group.main.arn]
  launch_configuration = aws_launch_configuration.app.id

  tag {
    key                 = "Name"
    value               = "AppInstance"
    propagate_at_launch = true
  }
}


