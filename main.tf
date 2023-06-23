resource "aws_vpc" "wordpress_vpc" {
  cidr_block = "10.0.0.0/16"  # Insira o bloco CIDR desejado para a VPC
}

resource "aws_subnet" "wordpress_subnet" {
  vpc_id                  = aws_vpc.wordpress_vpc.id
  cidr_block              = "10.0.0.0/24"  # Insira o bloco CIDR desejado para a subnet
  availability_zone       = "us-east-1a"  # Insira a zona de disponibilidade desejada
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Security group for WordPress"

  vpc_id = aws_vpc.wordpress_vpc.id

  ingress {
    from_port   = 22  # Porta SSH, ajuste conforme necessário
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Adicione outras regras de ingress conforme necessário para o WordPress e outros serviços

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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