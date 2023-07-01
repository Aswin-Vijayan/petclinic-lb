resource "aws_iam_instance_profile" "s3_access_instance_profile" {
  name = "instance-profile"

  role = "instance_role"
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-alb-sg"
  }
}

resource "aws_lb" "petclinic" {
  name               = "petclinic-alb"
  internal           = false
  load_balancer_type = "application"

  subnets         = var.subnets
  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_security_group" "instance_sg" {
  name_prefix = "petclinic-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petclinic-sg"
  }
}


resource "aws_lb_target_group" "petclinic" {
  name_prefix = "jks-lb"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/login"
    port                = 8080
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "aws_lb_listener" "petclinic" {
  load_balancer_arn = aws_lb.petclinic.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.petclinic.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "petclinic" {
  name_prefix   = "petclinic-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.s3_access_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance_sg.id]
  }

  user_data = base64encode(<<-EOT

    #!/bin/bash
    
    cd /home/ubuntu

    aws s3 cp s3://petclinic-project/jar/jmx_prometheus_javaagent-0.18.0.jar

    curl -u aswin:18NOV@99 -O http://http://54.244.121.108:8081/repository/maven-releases/petclinic-jarfile/org/springframework/boot/petclinic/3.0.7/petclinic-3.0.7.jar

    ./start.sh

  EOT
  )

}

resource "aws_autoscaling_group" "petclinic" {
  name                = "petclinic"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.petclinic.id
    version = aws_launch_template.petclinic.latest_version
  }

  tag {
    key                 = "Name"
    value               = "petclinic"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  # instance_refresh {
  #   strategy = "Rolling"
  #   triggers = ["launch_template"]
  # }
}


resource "aws_autoscaling_attachment" "petclinic" {
  autoscaling_group_name = aws_autoscaling_group.petclinic.name
  lb_target_group_arn    = aws_lb_target_group.petclinic.arn
}