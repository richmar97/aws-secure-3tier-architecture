# 1. Kryptografisch sicheres Passwort generieren (kein Hardcoding)
resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. AWS Secrets Manager Secret für Datenbank-Zugangsdaten anlegen
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}-rds-db-credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.environment}-rds-db-credentials"
  }
}

# 3. Secret-Inhalt (JSON) im Secrets Manager ablegen
resource "aws_secretsmanager_secret_version" "db_credentials_val" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    username = "dbadmin"
    password = random_password.db_password.result
    database = var.db_name
  })
}

# 4. Multi-AZ RDS PostgreSQL Instanz
resource "aws_db_instance" "postgres" {
  identifier        = "${var.environment}-postgres-db"
  allocated_storage = 20
  engine            = "postgres"
  engine_version    = "15.7"
  instance_class    = var.db_instance_class

  db_name  = var.db_name
  username = "dbadmin"
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # Hochverfügbarkeit & Isolation
  multi_az            = true
  publicly_accessible = false
  skip_final_snapshot = true

  # Verschlüsselung at Rest
  storage_encrypted = true

  tags = {
    Name = "${var.environment}-postgres-db"
    Tier = "Database"
  }
}
