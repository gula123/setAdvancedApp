import json
import boto3
import urllib.parse

# Initialize AWS clients
s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """
    Lambda function to process images from SQS queue, 
    run image recognition, and store results in DynamoDB
    """
    
    # Get environment variables
    dynamodb_table_name = context.get('dynamodb_table_name', 'image-recognition-results')
    
    try:
        # Process each record from SQS
        for record in event['Records']:
            # Parse the SQS message which contains SNS notification
            message_body = json.loads(record['body'])
            sns_message = json.loads(message_body['Message'])
            
            # Extract S3 bucket and object information
            for s3_record in sns_message['Records']:
                bucket_name = s3_record['s3']['bucket']['name']
                object_key = urllib.parse.unquote_plus(
                    s3_record['s3']['object']['key'], 
                    encoding='utf-8'
                )
                
                print(f"Processing image: {object_key} from bucket: {bucket_name}")
                
                # Call Amazon Rekognition to detect labels
                try:
                    response = rekognition_client.detect_labels(
                        Image={
                            'S3Object': {
                                'Bucket': bucket_name,
                                'Name': object_key
                            }
                        },
                        MaxLabels=10,
                        MinConfidence=70
                    )
                    
                    # Store results in DynamoDB
                    table = dynamodb.Table(dynamodb_table_name)
                    
                    for label in response['Labels']:
                        table.put_item(
                            Item={
                                'ImageName': object_key,
                                'LabelValue': label['Name'],
                                'Confidence': str(label['Confidence']),
                                'Timestamp': context.aws_request_id
                            }
                        )
                    
                    print(f"Successfully processed {object_key} with {len(response['Labels'])} labels")
                    
                except Exception as e:
                    print(f"Error processing image {object_key}: {str(e)}")
                    raise e
        
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully processed images')
        }
        
    except Exception as e:
        print(f"Error processing SQS message: {str(e)}")
        raise e