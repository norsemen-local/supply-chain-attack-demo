#!/bin/bash
# Setup AWS restricted IAM user for supply chain attack demo

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

USER_NAME="cortex-xdr-demo-restricted"
POLICY_NAME="CortexXDRDemoReadOnlyPolicy"

echo "=========================================="
echo "  AWS Infrastructure Setup"
echo "=========================================="
echo ""
echo "[*] Creating restricted IAM user: $USER_NAME"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "[-] Error: AWS CLI not configured"
    echo "    Run 'aws configure' first"
    exit 1
fi

echo "[*] Current AWS identity:"
aws sts get-caller-identity
echo ""

# Create IAM user
echo "[*] Creating IAM user..."
if aws iam get-user --user-name "$USER_NAME" &> /dev/null; then
    echo "[!] User already exists, using existing user"
else
    aws iam create-user --user-name "$USER_NAME" --tags Key=Purpose,Value=CortexXDRDemo
    echo "[+] User created"
fi

# Create and attach policy
echo "[*] Creating IAM policy..."
POLICY_ARN=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document file://restricted_user_policy.json \
    --description "Read-only enumeration policy for Cortex XDR supply chain attack demo" \
    --query 'Policy.Arn' \
    --output text 2>/dev/null || \
    aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

if [ -z "$POLICY_ARN" ]; then
    echo "[-] Failed to create or find policy"
    exit 1
fi

echo "[+] Policy ARN: $POLICY_ARN"

# Attach policy to user
echo "[*] Attaching policy to user..."
aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn "$POLICY_ARN" 2>/dev/null || echo "[!] Policy already attached"

# Create access key
echo "[*] Creating access key..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$USER_NAME" 2>/dev/null || echo "")

if [ -z "$ACCESS_KEY_OUTPUT" ]; then
    echo "[!] Access key may already exist. Delete old keys first with:"
    echo "    aws iam list-access-keys --user-name $USER_NAME"
    echo "    aws iam delete-access-key --user-name $USER_NAME --access-key-id <KEY_ID>"
    exit 1
fi

ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"AccessKeyId": "[^"]*' | cut -d'"' -f4)
SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"SecretAccessKey": "[^"]*' | cut -d'"' -f4)

echo ""
echo "[SUCCESS] AWS Infrastructure Setup Complete!"
echo ""
echo "=========================================="
echo "  Credentials for Demo"
echo "=========================================="
echo ""
echo "Access Key ID:     $ACCESS_KEY_ID"
echo "Secret Access Key: $SECRET_ACCESS_KEY"
echo ""

# Save credentials for victim endpoint
CREDS_FILE="demo_aws_credentials"
cat > "$CREDS_FILE" << EOF
[default]
aws_access_key_id = $ACCESS_KEY_ID
aws_secret_access_key = $SECRET_ACCESS_KEY
region = us-east-1
EOF

echo "[+] Credentials saved to: $CREDS_FILE"
echo ""
echo "To setup victim endpoint, copy credentials:"
echo "  mkdir -p ~/.aws"
echo "  cp $CREDS_FILE ~/.aws/credentials"
echo ""
echo "⚠️  SECURITY NOTE:"
echo "  This user has READ-ONLY enumeration permissions"
echo "  No destructive AWS operations are possible"
echo ""
