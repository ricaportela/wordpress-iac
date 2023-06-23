# Passo 2: Criação do Banco de Dados no RDS

resource "aws_db_instance" "wordpress_db" {
  identifier            = "wordpress-db"
  engine                = "mysql"
  instance_class        = "db.t2.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  username              = "db_user"  # Insira o nome de usuário desejado
  password              = "db_password"  # Insira a senha desejada
  db_subnet_group_name  = aws_db_subnet_group.wordpress_db_subnet.name
  vpc_security_group_ids = [aws_security_group.wordpress_db_sg.id]
}

resource "aws_db_subnet_group" "wordpress_db_subnet" {
  name       = "wordpress-db-subnet"
  subnet_ids = [aws_subnet.wordpress_subnet.id]
}