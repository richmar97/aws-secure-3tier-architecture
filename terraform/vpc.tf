# 1. Zentrales VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-3tier-vpc"
  }
}

# 2. Internet Gateway für die Public Subnets
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 3. Tier 1: Public Subnets (ALB Ingress)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# 4. Tier 2: App Subnets (Compute / Auto Scaling)
resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-app-subnet-${count.index + 1}"
    Tier = "App"
  }
}

# 5. Tier 3: Database Subnets (RDS Multi-AZ - Isoliert)
resource "aws_subnet" "db" {
  count             = length(var.db_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-db-subnet-${count.index + 1}"
    Tier = "Database"
  }
}

# DB Subnet Group für RDS
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-rds-subnet-group"
  subnet_ids  = aws_subnet.db[*].id
  description = "Subnet group for multi-AZ RDS deployment"

  tags = {
    Name = "${var.environment}-rds-subnet-group"
  }
}

# 6. Routing für Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
