variable "access_key" {
  description = "access_key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "secret_ket"
  type        = string
  sensitive   = true
}


variable "bucket_name" {
  description = "Nombre del bucket S3 donde Lambda escribira"
  type        = string
  default     = "data-s3-form-storage"
}


variable "lambda_function_name" {
  description = "Nombre de la función Lambda"
  type        = string
  default     = "mi-funcion-lambda"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Region de despliegue"
  type = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "mi-proyecto"
}
