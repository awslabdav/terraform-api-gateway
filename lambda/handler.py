import json
import boto3
import os
from datetime import datetime
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'data-s3-form-storage')

def lambda_handler(event, context):
    print("Evento recibido:", json.dumps(event))
    print(f"Bucket configurado: {BUCKET_NAME}")
    
    # Headers CORS (importante para que tu web pueda conectarse)
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS'
    }
    
    # Manejar preflight request (OPTIONS)
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({'message': 'OK - I have recived the event'})
        }
    
    # Manejar GET request (para pruebas)
    if event.get('httpMethod') == 'GET':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'API funcionando correctamente',
                'bucket': BUCKET_NAME,
                'endpoints': {
                    'POST /data': 'Guardar datos en S3',
                    'GET /data': 'Verificar estado de la API'
                },
                'timestamp': datetime.now().isoformat()
            })
        }
    
    try:
        # Parsar el body del request
        body = json.loads(event.get('body', '{}'))
        print(f"Datos recibidos: {json.dumps(body)}")
        
        # Validar datos requeridos
        if not body.get('key') or not body.get('value'):
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'message': 'key y value son requeridos'})
            }
        
        # Crear nombre de archivo único
        timestamp = datetime.now().strftime('%Y%m%d_%H%M')
        file_key = f"data/{body['key']}_{timestamp}.json"
        print(f"Guardando en S3 con key: {file_key}")
        
        # Verificar que el bucket existe
        try:
            s3_client.head_bucket(Bucket=BUCKET_NAME)
            print(f"Bucket {BUCKET_NAME} existe y es accesible") # Confirmacion del bucket
        except ClientError as e:
            error_code = e.response['Error']['Code']
            print(f"Error con bucket {BUCKET_NAME}: {error_code}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'message': f'Error con bucket S3: {error_code}'})
            }
        
        # Guardar en S3
        s3_client.put_object(
            Bucket=BUCKET_NAME,
            Key=file_key,
            Body=json.dumps(body, indent=2),
            ContentType='application/json'
        )
        
        print(f"Datos guardados exitosamente en {file_key}")
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Datos guardados exitosamente',
                's3_key': file_key,
                'bucket': BUCKET_NAME,
                'data': body
            })
        }
        
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {str(e)}")
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'message': 'JSON inválido'})
        }
    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"Error S3: {error_code} - {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': f'Error S3: {error_code}'})
        }
    except Exception as e:
        print(f"Error inesperado: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'message': f'Error: {str(e)}'})
        }
