#!/bin/bash
# Start C2 Listener Only

set -e

SERVER_IP="$1"

echo "=========================================="
echo "  Starting C2 Listener Only"
echo "=========================================="
echo ""

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

if [ -n "$SERVER_IP" ]; then
    echo "[*] Using specified IP: $SERVER_IP"
else
    echo "[*] Auto-detecting network IP..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "[*] Detected IP: $SERVER_IP"
fi

echo "[*] C2 Port: 4444"
echo ""

# Start C2 listener in foreground
echo "[*] Starting C2 credential receiver on port 4444..."
echo "[*] Waiting for connections..."
echo "[*] Press Ctrl+C to stop"
echo ""

python3 c2_listener_only.py
