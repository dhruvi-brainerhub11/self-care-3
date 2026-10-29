data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Web and SSH access to the self-care application."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP application traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-app"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "MySQL access from the application server and optional developer CIDR."
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "MySQL from the application server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  dynamic "ingress" {
    for_each = var.developer_cidr == "" ? [] : [var.developer_cidr]

    content {
      description = "Optional MySQL access for local development"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-database"
  }
}

resource "aws_db_subnet_group" "default_vpc" {
  name       = "${var.name}-db-subnets"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "${var.name}-db-subnets"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]

  root_block_device {
    encrypted   = true
    volume_size = 16
    volume_type = "gp3"
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.name}-server"
  }
}

resource "aws_db_instance" "app" {
  identifier              = var.name
  engine                  = "mysql"
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = 3306
  db_subnet_group_name    = aws_db_subnet_group.default_vpc.name
  vpc_security_group_ids  = [aws_security_group.database.id]
  publicly_accessible     = var.db_publicly_accessible
  multi_az                = var.db_multi_az
  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = true

  tags = {
    Name = "${var.name}-database"
  }
}