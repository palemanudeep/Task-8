provider "aws" {
  region = var.aws_region
}

# Data source to check if VPC exists
data "aws_vpc" "existing_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-vpc-service8"]
  }
}

# VPC creation (conditional)
resource "aws_vpc" "main_service8" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "medusa-vpc-service8"
  }

  # Create only if the VPC doesn't already exist
  count = length(data.aws_vpc.existing_service8.id) == 0 ? 1 : 0
}

# Subnet 1 (conditional)
data "aws_subnet" "public_subnet_1_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-public-subnet-1-service8"]
  }
}

resource "aws_subnet" "public_subnet_1_service8" {
  vpc_id            = aws_vpc.main_service8.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "medusa-public-subnet-1-service8"
  }

  count = length(data.aws_subnet.public_subnet_1_service8.id) == 0 ? 1 : 0
}

# Subnet 2 (conditional)
data "aws_subnet" "public_subnet_2_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-public-subnet-2-service8"]
  }
}

resource "aws_subnet" "public_subnet_2_service8" {
  vpc_id            = aws_vpc.main_service8.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "medusa-public-subnet-2-service8"
  }

  count = length(data.aws_subnet.public_subnet_2_service8.id) == 0 ? 1 : 0
}

# Internet Gateway (conditional)
data "aws_internet_gateway" "existing_gw_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-gw-service8"]
  }
}

resource "aws_internet_gateway" "gw_service8" {
  vpc_id = aws_vpc.main_service8.id

  tags = {
    Name = "medusa-gw-service8"
  }

  count = length(data.aws_internet_gateway.existing_gw_service8.id) == 0 ? 1 : 0
}

# Route table for public subnets (conditional)
data "aws_route_table" "existing_public_route_table_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-public-route-table-service8"]
  }
}

resource "aws_route_table" "public_route_table_service8" {
  vpc_id = aws_vpc.main_service8.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_service8.id
  }

  tags = {
    Name = "medusa-public-route-table-service8"
  }

  count = length(data.aws_route_table.existing_public_route_table_service8.id) == 0 ? 1 : 0
}

resource "aws_route_table_association" "public_subnet_1_service8" {
  subnet_id      = aws_subnet.public_subnet_1_service8.id
  route_table_id = aws_route_table.public_route_table_service8.id
}

resource "aws_route_table_association" "public_subnet_2_service8" {
  subnet_id      = aws_subnet.public_subnet_2_service8.id
  route_table_id = aws_route_table.public_route_table_service8.id
}

# Security Group for ECS (conditional)
data "aws_security_group" "existing_ecs_sg_service8" {
  filter {
    name   = "tag:Name"
    values = ["medusa-ecs-sg-service8"]
  }
}

resource "aws_security_group" "ecs_sg_service8" {
  vpc_id      = aws_vpc.main_service8.id
  description = "Allow inbound traffic for ECS services"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "medusa-ecs-sg-service8"
  }

  count = length(data.aws_security_group.existing_ecs_sg_service8.id) == 0 ? 1 : 0
}

# ECS Cluster (conditional)
data "aws_ecs_cluster" "existing_medusa_ecs_cluster_service8" {
  cluster_name = "medusa-ecs-cluster-service8"
}

resource "aws_ecs_cluster" "medusa_ecs_cluster_service8" {
  name = "medusa-ecs-cluster-service8"

  count = length(data.aws_ecs_cluster.existing_medusa_ecs_cluster_service8.id) == 0 ? 1 : 0
}

# IAM Role for ECS Task Execution (conditional)
data "aws_iam_role" "existing_ecs_task_execution_role_service8" {
  name = "ecsTaskExecutionRole-service8"
}

resource "aws_iam_role" "ecs_task_execution_role_service8" {
  name = "ecsTaskExecutionRole-service8"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  count = length(data.aws_iam_role.existing_ecs_task_execution_role_service8.id) == 0 ? 1 : 0
}

# IAM Policy Attachment for ECS Task Execution Role (conditional)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_service8" {
  role       = aws_iam_role.ecs_task_execution_role_service8.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definition (conditional)
resource "aws_ecs_task_definition" "medusa_task_service8" {
  family                = "medusa-task-service8"
  network_mode          = "awsvpc"
  cpu                   = 512
  memory                = 1024
  execution_role_arn    = aws_iam_role.ecs_task_execution_role_service8.arn
  requires_compatibilities = ["FARGATE"]

  container_definitions = <<DEFINITION
[
  {
    "name": "medusa-container-service8",
    "image": "${aws_ecr_repository.medusa_ecr_repo_service8.repository_url}:latest",
    "essential": true,
    "memory": 1024,
    "cpu": 512,
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

# ECR Repository (conditional)
data "aws_ecr_repository" "existing_medusa_ecr_repo_service8" {
  name = "medusa-backend-service8"
}

resource "aws_ecr_repository" "medusa_ecr_repo_service8" {
  name = "medusa-backend-service8"

  count = length(data.aws_ecr_repository.existing_medusa_ecr_repo_service8.id) == 0 ? 1 : 0
}

# RDS PostgreSQL Instance (conditional)
data "aws_db_instance" "existing_medusa_db_service8" {
  db_instance_identifier = "medusa-db-service8"
}

resource "aws_db_instance" "medusa_db_service8" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13"
  instance_class       = "db.t3.micro"
  db_name              = "medusadb-service8"
  username             = "medusa_user"
  password             = var.db_password
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.ecs_sg_service8.id]

  count = length(data.aws_db_instance.existing_medusa_db_service8.id) == 0 ? 1 : 0
}
