# API Gateway con Lambda y S3 - Terraform

## 📋 Descripción del Proyecto

Este proyecto implementa una infraestructura serverless en AWS usando Terraform, que incluye una función Lambda con acceso a S3, preparada para integrarse con API Gateway.

## 🏗️ Arquitectura

```
API Gateway (pendiente) → Lambda Function → S3 Bucket
                              ↓
                          IAM Roles & Policies
                              ↓
                          CloudWatch Logs
```

## 🚀 Recursos Implementados

### 1. **VPC (Virtual Private Cloud)**
- Red virtual aislada con CIDR `10.0.0.0/16`
- Proporciona aislamiento de red para los recursos

### 2. **S3 Bucket**
- Almacenamiento de datos para la aplicación
- Nombre configurable mediante variable `bucket_name`

### 3. **Lambda Function**
- Runtime: Python 3.12
- Handler: `handler.lambda_handler`
- Empaquetado automático desde carpeta local
- Variable de entorno: `BUCKET_NAME` (referencia al bucket S3)

### 4. **IAM Roles y Políticas**
- **Rol Lambda**: Permite que Lambda asuma el rol
- **Política S3**: Permisos para leer/escribir en S3
  - `s3:PutObject`
  - `s3:PutObjectAcl`
  - `s3:GetObject`
  - `s3:ListBucket`
- **Política CloudWatch**: Logs básicos de Lambda

## 📦 Características de API Gateway con Terraform

### Ventajas de Implementar API Gateway

1. **Gestión de Endpoints HTTP/REST**
   - Creación de APIs RESTful completas
   - Soporte para métodos HTTP (GET, POST, PUT, DELETE)
   - Rutas y recursos personalizables

2. **Integración con Lambda**
   - Invocación directa de funciones Lambda
   - Transformación de requests/responses
   - Manejo automático de escalado

3. **Seguridad**
   - Autenticación con API Keys
   - Integración con AWS Cognito
   - Autorización IAM
   - CORS configurable

4. **Monitoreo y Logging**
   - Integración con CloudWatch
   - Métricas de uso y latencia
   - Trazabilidad de requests

5. **Gestión de Versiones**
   - Stages (dev, staging, prod)
   - Despliegues controlados
   - Rollback fácil

## 📁 Estructura del Proyecto

```
terraform_api/
├── main.tf              # Configuración principal de infraestructura
├── variables.tf         # Variables de entrada 
├── lambda/              # Código de la función Lambda
│   └── handler.py       # Handler principal
└── README.md            # Este archivo
```

## 🔧 Configuración Inicial

### 1. Configurar Credenciales AWS
```bash
# Opción 1: Variables de entorno (recomendado)
export AWS_ACCESS_KEY_ID="tu-access-key"
export AWS_SECRET_ACCESS_KEY="tu-secret-key"

# Opción 2: AWS CLI
aws configure

# Opción 3: Archivo terraform.tfvars (NO subir al repo)
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus credenciales reales
```

### 2. Inicializar Terraform
```bash
terraform init
terraform plan
terraform apply
```

## 🔧 Variables Requeridas
Debes configurar tus credenciales AWS usando una de las opciones mencionadas en la sección de Configuración Inicial. **NUNCA** hardcodees credenciales en el código.


## ⚠️ Consideraciones de Seguridad

- **NO** hardcodear credenciales en el código
- Usar variables de entorno o AWS Secrets Manager
- Implementar principio de mínimo privilegio en políticas IAM
- Habilitar encriptación en S3
- Configurar CORS apropiadamente en API Gateway

## 📚 Recursos Adicionales

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
