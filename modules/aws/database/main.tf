resource "aws_db_subnet_group" "database_subnet_group" {
  name       = var.database_subnet_name
  subnet_ids = []
}

resource "aws_db_instance" "database_instance" {
  allocated_storage    = var.database_storage
  engine               = var.database_engine
  instance_class       = var.database_instance_class
  name                 = var.database_name
  username             = var.database_username
  password             = var.database_password
  db_subnet_group_name = var.database_subnet_name
  depends_on = ["aws_db_subnet_group.database_subnet_group"]
}