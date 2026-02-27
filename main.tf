terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Crear VPC
resource "aws_vpc" "main-vpc" {
  cidr_block = "10.0.0.0/16" # El bloque de direcciones IP para toda la VPC

  tags = {
    Name = "main-api-vpc"
  }
}

# Crear un S3 para almacenar los datos de la web page
resource "aws_s3_bucket" "data-s3" {
  bucket = var.bucket_name
}

# 2. Definir la Función Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"  # Carpeta con tu código
  output_path = "${path.module}/lambda-funtion.zip" # Zip generado
}

resource "aws_lambda_function" "mi_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "mi-funcion-lambda" # Nombre de la funcion lambda que se utiliza
  role             = aws_iam_role.lambda_s3_role.arn
  handler          = "handler.lambda_handler" # Para Pyhton
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data-s3.id
    }
  }
}

# Rol para Lambda -----------------------------------------------------------
resource "aws_iam_role" "lambda_s3_role" {
  name = "lambda-s3-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "lambda-s3-role"
    Environment = var.environment
  }
}

# Política para S3
resource "aws_iam_policy" "s3_policy" {
  name        = "lambda-s3-policy"
  description = "Permisos para Lambda escribir en S3"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.data-s3.id}",
          "arn:aws:s3:::${aws_s3_bucket.data-s3.id}/*"
        ]
      }
    ]
  })
}

# Adjuntar política S3
resource "aws_iam_role_policy_attachment" "attach_s3" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

# Política básica de Lambda para logs (AWSLambdaBasicExecutionRole)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
