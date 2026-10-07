# 1. Neuestes Amazon Linux 2023 AMI dynamisch abfragen
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. IAM Role für EC2 (Secrets Manager Zugriff)
resource "aws_iam_role" "app_role" {
  name = "${var.environment}-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_read_policy" {
  name        = "${var.environment}-secrets-read-policy"
  description = "Allows reading the database secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_read_policy.arn
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.environment}-app-instance-profile"
  role = aws_iam_role.app_role.name
}

# 3. Application Load Balancer (Tier 1)
resource "aws_lb" "external_alb" {
  name               = "${var.environment}-external-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.environment}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.environment}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Launch Template für Applikations-Instanzen (Tier 2)
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.environment}-app-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    arn = aws_iam_instance_profile.app_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>3-Tier App Tier Healthy | Host: $(hostname)</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment}-app-node"
      Tier = "App"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 5. Auto Scaling Group in den privaten App-Subnetzen

resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.environment}-app-asg-"
  vpc_zone_identifier = aws_subnet.app[*].id
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  lifecycle {
    create_before_destroy = true
  }
}
