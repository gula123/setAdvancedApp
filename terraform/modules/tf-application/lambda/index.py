import json
import boto3
from boto3.dynamodb.conditions import Attr
import datetime
import os
from botocore.config import Config

# Get environment variables
dynamodb_table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'setadvancedtable')
s3_bucket_name = os.environ.get('S3_BUCKET_NAME', 'default-bucket')
aws_region = os.environ.get('AWS_DEFAULT_REGION', 'eu-north-1')

# Configure timeouts for AWS clients
config = Config(
    connect_timeout=5,
    read_timeout=30,
    retries={'max_attempts': 3}
)

s3 = boto3.client("s3", region_name=aws_region, config=config)
rekognition = boto3.client("rekognition", region_name="eu-west-1", config=config)
dynamodb = boto3.resource("dynamodb", region_name=aws_region, config=config)
table = dynamodb.Table(dynamodb_table_name)

def is_image_file(key):
    return key.lower().endswith(('.jpg', '.jpeg', '.png'))

def lambda_handler(event, context):
    for event_record in event["Records"]:
        try:
            body = json.loads(event_record["body"])
            message = json.loads(body["Message"])

            for record in message["Records"]:
                bucket = record["s3"]["bucket"]["name"]
                key = record["s3"]["object"]["key"]

                print(f"Processing S3 object: bucket={bucket}, key={key}")

                if not is_image_file(key):
                    print(f"Skipping non-image file: {key}")
                    continue

                try:
                    s3_response = s3.get_object(Bucket=bucket, Key=key)
                    image_bytes = s3_response['Body'].read()
                except Exception as e:
                    print(f"S3 get_object error for {key}: {e}")
                    continue

                try:
                    response = rekognition.detect_labels(
                        Image={'Bytes': image_bytes},
                        MaxLabels=10,
                        MinConfidence=75
                    )
                except Exception as e:
                    print(f"Rekognition error for {key}: {e}")
                    continue

                labels = [label["Name"] for label in response["Labels"]]
                now = datetime.datetime.now()
                iso_time = now.strftime('%Y-%m-%dT%H:%M:%S.%f') + '000'

                scan_response = table.scan(
                    FilterExpression=Attr("objectPath").eq(key)
                )

                if not scan_response.get("Items"):
                    print(f"No item found in DynamoDB with objectPath={key}")
                    continue

                for item in scan_response["Items"]:
                    item_id = item["id"]
                    try:
                        table.update_item(
                            Key={
                                "id": item_id,
                                "objectPath": key
                            },
                            UpdateExpression="""
                                ADD labels :new_labels
                                SET #status = :status,
                                    timeUpdated = :timeUpdated
                            """,
                            ExpressionAttributeValues={
                                ":new_labels": set(labels),
                                ":status": "ACTIVE",
                                ":timeUpdated": iso_time,
                            },
                            ExpressionAttributeNames={
                                "#status": "status"
                            }
                        )
                        print(f"Updated item with id={item_id} and objectPath={key}")
                    except Exception as e:
                        print(f"Error updating DynamoDB for id={item_id}, key={key}: {e}")

        except Exception as e:
            # Catch any unexpected errors and log them, so no message remains in queue
            print(f"General error in event record: {e}")