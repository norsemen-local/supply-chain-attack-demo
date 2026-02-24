#!/bin/bash
# Start PyPI Server Only

set -e

SERVER_IP="$1"

echo "=========================================="
echo "  Starting PyPI Server Only"
echo "=========================================="
echo ""

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Create packages directory if it doesn't exist
mkdir -p packages/simple

if [ -n "$SERVER_IP" ]; then
    echo "[*] Using specified IP: $SERVER_IP"
else
    echo "[*] Auto-detecting network IP..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "[*] Detected IP: $SERVER_IP"
fi

echo "[*] PyPI URL: http://$SERVER_IP:8080/simple/"
echo ""

# Start PyPI server in foreground
echo "[*] Starting PyPI server on port 8080..."
echo "[*] Press Ctrl+C to stop"
echo ""

cd packages
python3 -m http.server 8080 --bind 0.0.0.0
