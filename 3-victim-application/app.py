#!/usr/bin/env python3
"""
Legitimate Data Processing Application
Uses aws-data-utils for S3 data processing
"""
import boto3
from aws_data_utils import validate_s3_path, parse_s3_uri, format_dynamodb_item


def process_s3_data():
    """Process data from S3 buckets"""
    print("[App] Starting data processing application...")
    
    # Example S3 operations
    s3_uri = "s3://my-data-bucket/data/file.csv"
    
    try:
        validate_s3_path(s3_uri)
        bucket, key = parse_s3_uri(s3_uri)
        print(f"[App] Processing data from bucket: {bucket}")
        print(f"[App] File key: {key}")
    except Exception as e:
        print(f"[App] Error: {e}")
    
    # List S3 buckets (requires AWS credentials)
    try:
        s3_client = boto3.client('s3')
        buckets = s3_client.list_buckets()
        print(f"[App] Found {len(buckets.get('Buckets', []))} S3 buckets")
    except Exception as e:
        print(f"[App] Could not list buckets: {e}")
    
    print("[App] Data processing complete")


def process_dynamodb_data():
    """Process DynamoDB data"""
    sample_item = {
        'id': '12345',
        'name': 'Sample Record',
        'timestamp': '2024-01-01'
    }
    
    formatted = format_dynamodb_item(sample_item)
    print(f"[App] Formatted DynamoDB item: {formatted}")


def main():
    """Main application entry point"""
    print("=" * 60)
    print("  Data Processing Application")
    print("=" * 60)
    print()
    
    process_s3_data()
    print()
    process_dynamodb_data()
    
    print()
    print("[App] Application finished successfully")


if __name__ == "__main__":
    main()
