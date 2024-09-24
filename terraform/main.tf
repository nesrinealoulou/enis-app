terraform {
  # Assumes s3 bucket and dynamo DB table already set up
  # See /code/03-basics/aws-backend
  backend "s3" {
    bucket         = "enis-terraform-for-state-file-0125"
    key            = "03-basics/web-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking-1256"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "enis-terraform-for-state-file-0125"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_crypto_conf" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_vpc" "tp_cloud_devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "tp_cloud_devops_vpc"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.tp_cloud_devops_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_gateway.id
  }


  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.tp_cloud_devops_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.tp_cloud_devops_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true


  tags = {
    Name = "PublicSubnet2"
  }
}


resource "aws_internet_gateway" "main_gateway" {
  vpc_id = aws_vpc.tp_cloud_devops_vpc.id
  tags = {
    Name = "MainInternetGateway"
  }
}



resource "aws_route_table_association" "public_rta1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_rta2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}




resource "aws_security_group" "web_sg" {
  name   = "web-server-sg"
  vpc_id = aws_vpc.tp_cloud_devops_vpc.id
  description = "Security group for web server access"
}

resource "aws_security_group_rule" "allow_web_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 81// Corrected to match the web server port
  to_port           = 81
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  // Allows access from any IP address
}

resource "aws_security_group_rule" "allow_container_port_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 8001// Corrected to match the web server port
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  // Allows access from any IP address
}

resource "aws_security_group_rule" "allow_web_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 22  // SSH port for administrative access
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"  # -1 allows all protocols
  cidr_blocks       = ["0.0.0.0/0"]  # Allows traffic to all IPs
}


resource "aws_instance" "example_instance" {
  ami           = "ami-0a0e5d9c7acc336f1" # Amazon Linux 2 AMI
  instance_type = "t2.micro"              # Adjust instance type as needed

  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id] 
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp2"
    volume_size = 50 # Adjust volume size as needed
  }

  key_name = "myjupt"
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, World 2" > index.html
              python3 -m http.server 8085 &
              EOF

  tags = {
    Name = "PublicInstance"
  }
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.example_instance.public_ip
}

resource "aws_security_group" "database_sg" {
  name   = "database-sg"
  vpc_id = aws_vpc.tp_cloud_devops_vpc.id
  description = "Security group for rds database"
}

resource "aws_security_group_rule" "allow_mysql_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.database_sg.id  # Attach to your RDS security group
  from_port         = 3306                          # MySQL default port
  to_port           = 3306                          # MySQL default port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]                 # Allow access from any IP (use cautiously)
}

resource "aws_security_group_rule" "allow_outbound_traffic" {
  type              = "egress"
  security_group_id = aws_security_group.database_sg.id  # Attach to your RDS security group
  from_port         = 0
  to_port           = 0
  protocol          = "-1"  # "-1" means all protocols
  cidr_blocks       = ["0.0.0.0/0"]  # Allow outbound traffic to any destination
}

resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "database-subnet-group"
  description = "Subnet group for RDS database"
  subnet_ids  = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "DatabaseSubnetGroup"
  }
}

resource "aws_db_instance" "db_instance" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.r5d.large"
  identifier             = "mydb"
  username               = "dbuser"
  password               = "dbpassword"
  vpc_security_group_ids = [aws_security_group.database_sg.id]  # Attach the database security group
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  skip_final_snapshot    = false  # Enable automated backups
  final_snapshot_identifier = "mydb-final-snapshot" 
}