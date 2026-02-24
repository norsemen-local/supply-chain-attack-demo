#!/bin/bash
# Start Attacker Infrastructure (C2 + PyPI Server)
# NOTE: Requires sudo/root - ports 80 and 443 are privileged ports

set -e

# Check for root privileges (required for ports 80 and 443)
if [ "$(id -u)" -ne 0 ]; then
    echo "[-] Error: This script must be run as root (sudo)"
    echo "    Ports 80 and 443 are privileged and require root access"
    echo ""
    echo "    Usage: sudo $0"
    exit 1
fi

echo "=========================================="
echo "  Starting Attacker Infrastructure"
echo "=========================================="
echo ""

# Check if ports 80 or 443 are already in use
PORTS_IN_USE=0
for PORT in 80 443; do
    PID=$(lsof -ti :$PORT 2>/dev/null || true)
    if [ -n "$PID" ]; then
        PROCESS_INFO=$(ps -p $PID -o pid=,comm= 2>/dev/null || echo "$PID (unknown)")
        echo "[!] WARNING: Port $PORT is already in use!"
        echo "    Process: $PROCESS_INFO"
        echo ""
        echo "    To free this port, you can run:"
        echo "      sudo kill $PID        # Graceful stop"
        echo "      sudo kill -9 $PID     # Force stop"
        echo ""
        PORTS_IN_USE=1
    fi
done

if [ "$PORTS_IN_USE" -eq 1 ]; then
    echo "-------------------------------------------"
    read -p "[?] Ports are in use. Kill the processes and continue? (y/N): " REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        for PORT in 80 443; do
            PID=$(lsof -ti :$PORT 2>/dev/null || true)
            if [ -n "$PID" ]; then
                echo "[*] Killing process on port $PORT (PID: $PID)..."
                kill $PID 2>/dev/null || kill -9 $PID 2>/dev/null || true
                sleep 1
            fi
        done
        echo "[+] Ports freed successfully"
        echo ""
    else
        echo "[-] Aborting. Free the ports manually and try again."
        exit 1
    fi
fi

# Get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

# Create packages directory if it doesn't exist
mkdir -p packages/simple

echo "[*] Installing dependencies..."
pip install -q -r requirements.txt

echo "[*] Starting C2 server with integrated PyPI server..."
echo "[*] Ports: 80 (PyPI) and 443 (C2)"
echo "[*] Press Ctrl+C to stop"
echo ""

# Run the C2 server
python3 c2_server.py
