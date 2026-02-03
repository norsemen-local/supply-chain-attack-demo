# Setup AWS Credentials on Victim (Windows Version)
# Simulates a developer workstation with AWS credentials

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Setting up AWS Credentials (Victim)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }

# Get the demo credentials file
$DemoCredsFile = Join-Path (Split-Path $ScriptDir -Parent) "5-aws-infrastructure\demo_aws_credentials"

if (-not (Test-Path $DemoCredsFile)) {
    Write-Host "[-] Error: Demo credentials file not found at: $DemoCredsFile" -ForegroundColor Red
    Write-Host "    Make sure you've run the AWS setup script first." -ForegroundColor Red
    exit 1
}

# Create .aws directory
$AwsDir = Join-Path $env:USERPROFILE ".aws"
New-Item -ItemType Directory -Force -Path $AwsDir | Out-Null

# Copy credentials file
$CredsFile = Join-Path $AwsDir "credentials"
Copy-Item $DemoCredsFile $CredsFile -Force

Write-Host "[+] AWS credentials copied to: $CredsFile" -ForegroundColor Green
Write-Host ""

# Parse credentials and set environment variables
Write-Host "[*] Loading credentials into environment variables..." -ForegroundColor Yellow

$CredsContent = Get-Content $CredsFile
$AccessKeyId = ($CredsContent | Select-String "aws_access_key_id").ToString().Split("=")[1].Trim()
$SecretAccessKey = ($CredsContent | Select-String "aws_secret_access_key").ToString().Split("=")[1].Trim()
$Region = ($CredsContent | Select-String "region").ToString().Split("=")[1].Trim()

# Set environment variables (current session)
$env:AWS_ACCESS_KEY_ID = $AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $SecretAccessKey
$env:AWS_DEFAULT_REGION = $Region

Write-Host "[+] Environment variables set for current session:" -ForegroundColor Green
Write-Host "    AWS_ACCESS_KEY_ID     = $AccessKeyId" -ForegroundColor Gray
Write-Host "    AWS_SECRET_ACCESS_KEY = ****...$(($SecretAccessKey).Substring($SecretAccessKey.Length - 4))" -ForegroundColor Gray
Write-Host "    AWS_DEFAULT_REGION    = $Region" -ForegroundColor Gray
Write-Host ""

# Verify AWS CLI can access
Write-Host "[*] Verifying AWS CLI access..." -ForegroundColor Yellow
try {
    $Identity = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[+] AWS CLI verification successful!" -ForegroundColor Green
        Write-Host $Identity
    } else {
        Write-Host "[-] Warning: AWS CLI verification failed" -ForegroundColor Yellow
        Write-Host $Identity -ForegroundColor Gray
    }
} catch {
    Write-Host "[-] Warning: Could not verify AWS CLI (may not be installed)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[SUCCESS] AWS credentials configured!" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: Credentials are stored in TWO locations (simulating real developer workstation):" -ForegroundColor Cyan
Write-Host "   1. File: $CredsFile" -ForegroundColor Gray
Write-Host "   2. Environment variables (current session)" -ForegroundColor Gray
Write-Host ""
Write-Host "The malicious package will steal credentials from BOTH locations!" -ForegroundColor Yellow
Write-Host ""
