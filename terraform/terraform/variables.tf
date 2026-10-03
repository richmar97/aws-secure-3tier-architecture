variable "aws_region" {
  description = "AWS deployment region"
  type        = STRING
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment stage"
  type        = STRING
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = STRING
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use for high availability"
  type        = list(STRING)
  default     = ["eu-central-1a", "eu-central-1b"]
}

# Subnet CIDR Definitions
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public ingress subnets (ALB)"
  type        = list(STRING)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for compute tier (EC2 / Auto Scaling)"
  type        = list(STRING)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for database tier (RDS Multi-AZ)"
  type        = list(STRING)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# Database Configuration
variable "db_name" {
  description = "Name of the default database"
  type        = STRING
  default     = "appdb"
}

variable "db_instance_class" {
  description = "Instance type for RDS PostgreSQL"
  type        = STRING
  default     = "db.t4g.micro"
}
