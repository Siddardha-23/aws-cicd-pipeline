################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

################################################################################
# Random Password
################################################################################

resource "random_password" "db" {
  length  = 16
  special = false
}

################################################################################
# RDS Instance
################################################################################

resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-db"

  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az            = false
  publicly_accessible = false

  skip_final_snapshot     = true
  backup_retention_period = 7
  deletion_protection     = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db"
  })
}
