#!/bin/bash

# --- Configuration ---
RESOLUTION="1920x1080"
VNC_PORT=5900
VNC_PASSWORD="1234"
TMP_SSH_PORT=2222
TUNNEL_USER="vncuser"
TUNNEL_PASS="vncpass123"
TMP_SSHD_CONFIG="/tmp/ephemeral_sshd_config"
TMP_SSHD_PID_FILE="/tmp/ephemeral_sshd.pid"

# --- Functions ---

create_limited_user() {
    echo "[+] Creating limited user '$TUNNEL_USER'..."
    sudo useradd -M -N -s /usr/sbin/nologin "$TUNNEL_USER"
    echo "$TUNNEL_USER:$TUNNEL_PASS" | sudo chpasswd
}

create_ed25519_key() {
    local keyfile="/etc/ssh/ssh_host_ed25519_key"
    if [[ -f "$keyfile" && -f "${keyfile}.pub" ]]; then
        echo "[+] Ed25519 host key already exists."
    else
        echo "[*] Ed25519 host key not found. Generating a new one..."
        sudo ssh-keygen -t ed25519 -f "$keyfile" -N ""
        echo "[+] Ed25519 host key generated."
    fi
}

generate_sshd_config() {
    echo "[+] Generating temporary SSH server config..."
    cat <<EOF > "$TMP_SSHD_CONFIG"
Port $TMP_SSH_PORT
ListenAddress 0.0.0.0
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
PasswordAuthentication yes
PubkeyAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
AllowUsers $TUNNEL_USER
PermitEmptyPasswords no
AllowTcpForwarding yes
PermitTTY no
X11Forwarding no
PrintMotd no
ForceCommand echo "This account can only be used for SSH tunneling."
PidFile $TMP_SSHD_PID_FILE
EOF
}

start_temp_ssh_server() {
    generate_sshd_config
    echo "[+] Starting temporary SSH server on port $TMP_SSH_PORT..."
    sudo /usr/sbin/sshd -f "$TMP_SSHD_CONFIG"

    sleep 1
    if [[ -f "$TMP_SSHD_PID_FILE" ]] && ps -p $(cat "$TMP_SSHD_PID_FILE") > /dev/null 2>&1; then
        echo "[+] SSH server running (PID: $(cat $TMP_SSHD_PID_FILE))"
    else
        echo "[-] Failed to start SSH server."
        exit 1
    fi
}

start_virtual_monitor() {
    echo "[+] Starting virtual VNC session..."
    krfb-virtualmonitor \
        --resolution "$RESOLUTION" \
        --name "Virtual Monitor" \
        --password "$VNC_PASSWORD" \
        --port "$VNC_PORT"
}

print_instructions() {
    echo ""
    echo "=========================================================="
    echo "🔐 Secure SSH Tunnel for VNC Access"
    echo ""
    echo "SSH Command (from client):"
    echo "  ssh -L 5900:localhost:$VNC_PORT $TUNNEL_USER@<server-ip> -p $TMP_SSH_PORT"
    echo ""
    echo "Login password: $TUNNEL_PASS"
    echo "Then open VNC Viewer and connect to: localhost:5900"
    echo "VNC password: $VNC_PASSWORD"
    echo "=========================================================="
}

cleanup() {
    echo "[*] Cleaning up..."
    if [[ -f "$TMP_SSHD_PID_FILE" ]]; then
        sudo kill "$(cat "$TMP_SSHD_PID_FILE")" 2>/dev/null
        sudo rm -f "$TMP_SSHD_PID_FILE"
    fi
    rm -f "$TMP_SSHD_CONFIG"
    echo "[+] Stopped temporary SSH server."

    echo "[+] Deleting temporary user '$TUNNEL_USER'..."
    sudo userdel "$TUNNEL_USER"
    sudo rm -rf /var/mail/"$TUNNEL_USER"
}

trap cleanup EXIT

# --- Execute ---
create_limited_user
create_ed25519_key
start_temp_ssh_server
print_instructions
start_virtual_monitor
