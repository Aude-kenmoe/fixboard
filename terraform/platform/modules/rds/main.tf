locals {
  parameter_group_family = "postgres${split(".", var.engine_version)[0]}"
}

# URL-safe password so it can be used inside a connection string.
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_security_group" "db" {
  name        = "${var.name}-rds"
  description = "PostgreSQL access from the cluster nodes"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "from_nodes" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.allowed_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from the EKS nodes"
}

# Teaching trade-off: the app connects without TLS. A production setup would
# keep rds.force_ssl on and ship the RDS CA bundle with the application.
resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = local.parameter_group_family
  description = "FixBoard PostgreSQL parameters"

  parameter {
    name         = "rds.force_ssl"
    value        = "0"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-postgres"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.username
  password = random_password.db.result

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az            = var.multi_az
  publicly_accessible = false

  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  apply_immediately          = true

  # Teaching environment: make "terraform destroy" clean and fast.
  skip_final_snapshot = true
  deletion_protection = false

  lifecycle {
    ignore_changes = [engine_version]
  }
}
