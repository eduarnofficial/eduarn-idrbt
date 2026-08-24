terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_api_gateway_rest_api" "securebank" {
  name        = var.api_name
  description = "SecureBank demo API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.securebank.id
  parent_id   = aws_api_gateway_rest_api.securebank.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.securebank.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = aws_api_gateway_rest_api.securebank.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method              = aws_api_gateway_method.proxy_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "${var.backend_url}/{proxy}"
}

resource "aws_api_gateway_method" "root_any" {
  rest_api_id   = aws_api_gateway_rest_api.securebank.id
  resource_id   = aws_api_gateway_rest_api.securebank.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.securebank.id
  resource_id             = aws_api_gateway_rest_api.securebank.root_resource_id
  http_method              = aws_api_gateway_method.root_any.http_method
  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = var.backend_url
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.securebank.id

  depends_on = [
    aws_api_gateway_integration.proxy,
    aws_api_gateway_integration.root
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.proxy_any.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_method.root_any.id,
      aws_api_gateway_integration.root.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.securebank.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = "prod"
}

resource "aws_api_gateway_usage_plan" "securebank" {
  name = "${var.api_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.securebank.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.securebank.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}"
}
