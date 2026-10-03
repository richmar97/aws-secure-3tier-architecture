# 1. Security Group für den Application Load Balancer (Tier 1)
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Controls public inbound traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow inbound HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to app tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# 2. Security Group für Applikation / EC2 Instances (Tier 2)
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Allows traffic strictly from ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP only from ALB SG"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

# 3. Security Group für RDS PostgreSQL (Tier 3)
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allows DB traffic strictly from App security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL access from App SG only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow outbound responses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}
