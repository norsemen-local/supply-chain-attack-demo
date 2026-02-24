# Supply Chain Attack Demo - Malicious Package to Cloud Exploitation

Demonstrates a realistic supply chain attack: malicious package installation → AWS credential theft → cloud enumeration.

## Attack Flow

```
Developer Endpoint → Malicious PyPI Package → C2 Server (Fake WAN) → AWS Cloud Enumeration
```

**Phase 1**: Developer installs package from attacker-controlled PyPI server
**Phase 2**: Malicious package steals AWS credentials during installation
**Phase 3**: Credentials exfiltrated to C2 server in fake WAN network
**Phase 4**: Attacker uses stolen credentials for AWS enumeration

## Project Structure

```
python-pack/
├── README.md                          # This file
├── 1-attacker-infrastructure/         # C2 + PyPI server (fake WAN)
│   ├── c2_server.py                   # Credential receiver + PyPI server
│   ├── start_infrastructure.sh        # Launch attacker infrastructure
│   └── requirements.txt               # Server dependencies
├── 2-malicious-package/               # Supply chain attack package
│   ├── setup.py                       # Steals credentials on install
│   ├── aws_data_utils/                # Realistic package name
│   │   └── __init__.py                # Runtime credential theft
│   └── build_and_upload.sh            # Build package for PyPI server
├── 3-victim-application/              # Developer's legitimate app
│   ├── requirements.txt               # Includes malicious dependency
│   ├── app.py                         # Simple data processing app
│   └── setup_victim.sh                # Configure to use attacker PyPI
├── 4-attacker-operations/             # Cloud attack phase
│   ├── enumerate_aws.py               # AWS enumeration
│   ├── requirements.txt               # boto3
│   └── run_attack.sh                  # Execute cloud operations
├── 5-aws-infrastructure/              # Victim AWS environment
│   ├── restricted_user.json           # IAM policy (read-only)
│   └── setup_aws.sh                   # Create restricted IAM user
└── demo_full_attack.sh                # Complete end-to-end demo
```

## Prerequisites

- **C2/Attacker Machine**: Python 3.8+, on separate network (fake WAN)
- **Victim Endpoint**: Python 3.8+, Windows or Linux with Cortex XDR
- **AWS Account**: For creating restricted IAM user

## Quick Start

### 1. Setup Attacker Infrastructure (C2 Server - Fake WAN)

```bash
cd 1-attacker-infrastructure/
pip install -r requirements.txt
./start_infrastructure.sh
# Note the C2 server IP for victim configuration
```

### 2. Setup AWS Restricted User (One-time)

```bash
cd 5-aws-infrastructure/
./setup_aws.sh
# Saves credentials to victim endpoint
```

### 3. Build Malicious Package

```bash
cd 2-malicious-package/
# Edit setup.py to set C2_SERVER_IP
./build_and_upload.sh <C2_SERVER_IP>
```

### 4. Setup Victim Endpoint

```bash
cd 3-victim-application/
./setup_victim.sh <C2_SERVER_IP>
```

### 5. Trigger Attack

```bash
# On victim endpoint
cd 3-victim-application/
pip install -r requirements.txt  # Steals credentials
python app.py                     # Runtime exfiltration (optional)

# On attacker C2 (after credentials received)
cd 4-attacker-operations/
./run_attack.sh
```

## Detection Opportunities

### Cortex XDR Should Detect:
- **Phase 1**: Suspicious network connection during package installation
- **Phase 2**: Python process accessing `~/.aws/credentials`
- **Phase 3**: Outbound connection to unusual IP during pip install
- **Phase 4**: AWS API enumeration from unexpected source IP
- **Phase 4**: High-volume AWS API calls (enumeration pattern)

## Security Notes

⚠️ **CONTROLLED LAB ENVIRONMENT ONLY**
- Restricted IAM user has ONLY read permissions (List/Get/Describe)
- No destructive AWS operations possible
- Malicious package only exfiltrates to designated C2
- All activities monitored by Cortex XDR

## Cleanup

```bash
# Remove attacker package from victim
pip uninstall aws-data-utils -y

# Stop C2 server
pkill -f c2_server.py

# Delete AWS IAM user (optional)
aws iam delete-access-key --user-name demo-restricted-user --access-key-id <KEY_ID>
aws iam detach-user-policy --user-name demo-restricted-user --policy-arn <POLICY_ARN>
aws iam delete-user --user-name demo-restricted-user
```
