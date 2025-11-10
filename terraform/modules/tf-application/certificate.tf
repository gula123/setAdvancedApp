# SSL/TLS Certificate for ALB
resource "aws_acm_certificate" "app_cert" {
  count             = var.enable_https && var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "app-cert-${var.environment}"
    Environment = var.environment
  }
}

# Self-signed certificate for development/testing when no domain is provided
resource "tls_private_key" "app_key" {
  count     = var.enable_https && var.domain_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_cert" {
  count           = var.enable_https && var.domain_name == "" ? 1 : 0
  private_key_pem = tls_private_key.app_key[0].private_key_pem

  subject {
    common_name  = "app-${var.environment}.local"
    organization = "Development"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "self_signed_cert" {
  count            = var.enable_https && var.domain_name == "" ? 1 : 0
  private_key      = tls_private_key.app_key[0].private_key_pem
  certificate_body = tls_self_signed_cert.app_cert[0].cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "app-self-signed-cert-${var.environment}"
    Environment = var.environment
  }
}

# Local values for certificate ARN
locals {
  certificate_arn = var.enable_https ? (
    var.domain_name != "" ? 
    aws_acm_certificate.app_cert[0].arn : 
    aws_acm_certificate.self_signed_cert[0].arn
  ) : null
}