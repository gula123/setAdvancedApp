# Default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "Default subnet for ${data.aws_availability_zones.available.names[0]}"
    Environment = var.environment
  }
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "Default subnet for ${data.aws_availability_zones.available.names[1]}"
    Environment = var.environment
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "vpc-endpoints-${var.environment}"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "vpc-endpoints-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint for S3 (Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "s3-endpoint-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint for DynamoDB (Gateway)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = data.aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "dynamodb-endpoint-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint for ECR DKR (Interface)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-dkr-endpoint-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint for ECR API (Interface)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "ecr-api-endpoint-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint for CloudWatch Logs (Interface)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name        = "logs-endpoint-${var.environment}"
    Environment = var.environment
  }
}