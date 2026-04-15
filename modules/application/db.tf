resource "aws_db_subnet_group" "main" {
  name       = "${local.deploy_name}-db-subnet"
  subnet_ids = var.private_db_subnet_ids
  tags       = local.common_tags
}

resource "aws_db_instance" "main" {
  identifier                  = "${local.deploy_name}-db"
  db_name                     = var.db_name
  engine                      = "mysql"
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [var.db_security_group_id]

  backup_retention_period = var.db_backup_retention_period
  multi_az                = false
  publicly_accessible     = false
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = local.common_tags
}
