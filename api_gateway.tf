# ============================================================================
# API GATEWAY REST API
# ============================================================================

resource "aws_api_gateway_rest_api" "data_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "API para guardar datos en S3"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Recurso /data
resource "aws_api_gateway_resource" "data_resource" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "data"
}

resource "aws_api_gateway_resource" "data_s3_resource" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  #parent_id   = aws_api_gateway_resource.data_resource.id
  parent_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  path_part   = "{object}"
}

# ============================================================================
# MÉTODO POST /data
# ============================================================================

resource "aws_api_gateway_method" "post_data" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.data_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integración Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.data_api.id
  resource_id             = aws_api_gateway_resource.data_resource.id
  http_method             = aws_api_gateway_method.post_data.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.mi_lambda.invoke_arn
}

# Method Response para POST (necesario para CORS)
resource "aws_api_gateway_method_response" "post_response_200" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.post_data.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# ============================================================================
# MÉTODO GET /{object} (obtener un archivo específico)
# ============================================================================

resource "aws_api_gateway_method" "get_object" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.data_s3_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.object" = true
  }
}

resource "aws_api_gateway_integration" "s3_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_s3_resource.id
  http_method = aws_api_gateway_method.get_object.http_method
  
  type = "AWS"
  integration_http_method = "GET"
  uri = "arn:aws:apigateway:${var.region}:s3:path/${var.bucket_name}/data/{object}"
  credentials = aws_iam_role.api_gateway_s3_role.arn
  
  request_parameters = {
    "integration.request.path.object" = "method.request.path.object"
  }
}

resource "aws_api_gateway_integration_response" "s3_get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_s3_resource.id
  http_method = aws_api_gateway_method.get_object.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.s3_get_integration
  ]
}

resource "aws_api_gateway_method_response" "get_object_response_200" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_s3_resource.id
  http_method = aws_api_gateway_method.get_object.http_method
  status_code = "200"
}

# Rol y politica para acceso a s3
resource "aws_iam_role" "api_gateway_s3_role" {
  name = "api-gateway-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "API Gateway S3 Access Role"
  }
}

resource "aws_iam_policy" "api_gateway_s3_policy" {
  name        = "api-gateway-s3-policy"
  description = "Policy for API Gateway to access specific S3 path"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_s3_policy_attachment" {
  role       = aws_iam_role.api_gateway_s3_role.name
  policy_arn = aws_iam_policy.api_gateway_s3_policy.arn
}


# Para manejar errores también
# resource "aws_api_gateway_method_response" "response_404" {
#   rest_api_id = aws_api_gateway_rest_api.data_api.id
#   resource_id = aws_api_gateway_resource.data_resource.id
#   http_method = aws_api_gateway_method.get_data.http_method
#   status_code = "404"

#   response_models = {
#     "application/json" = "Error"
#   }
# }

# ============================================================================
# MÉTODO OPTIONS /data (para CORS)  (Cross-Origin Resource Sharing //       Intercambio de Recursos de Origen Cruzado)
# ============================================================================

resource "aws_api_gateway_method" "options_data" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_resource.data_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.options_data.http_method
  type        = "MOCK"
  
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.options_data.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  resource_id = aws_api_gateway_resource.data_resource.id
  http_method = aws_api_gateway_method.options_data.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ============================================================================
# DEPLOYMENT Y STAGE
# ============================================================================

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id
  
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration.s3_get_integration,
    aws_api_gateway_method_response.post_response_200
  ]

   # ¡ESTA PARTE ES CRÍTICA! 
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_object.id,
      aws_api_gateway_integration.s3_get_integration.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_method_response.post_response_200.id,
    ]))
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  stage_name    = var.environment
}

# ============================================================================
# PERMISOS PARA QUE API GATEWAY INVOQUE LAMBDA
# ============================================================================

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mi_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.data_api.execution_arn}/*/*"
}

# ============================================================================
# OUTPUTS - URLs importantes
# ============================================================================

output "api_gateway_url" {
  description = "URL de tu API Gateway - Copia esto en app.js"
  value       = "${aws_api_gateway_stage.api_stage.invoke_url}/data"
}

output "api_gateway_id" {
  description = "ID del API Gateway"
  value       = aws_api_gateway_rest_api.data_api.id
}
