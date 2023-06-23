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
