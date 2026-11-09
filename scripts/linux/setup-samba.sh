#!/usr/bin/env bash
#
# Create a simple Samba share for the Windows direct-link peer.
#
# Usage:
#   sudo ./setup-samba.sh [share_path] [samba_user] [share_name] [windows_ip]
#
# Defaults:
#   /srv/share  $SUDO_USER  share  10.10.10.1
#
# Examples:
#   sudo ./setup-samba.sh
#   sudo ./setup-samba.sh /srv/share youruser share 10.10.10.1
#
# Review the script before running. It edits /etc/samba/smb.conf.
#
set -euo pipefail

SHARE_PATH="${1:-/srv/share}"
SAMBA_USER="${2:-${SUDO_USER:-$USER}}"
SHARE_NAME="${3:-share}"
WINDOWS_IP="${4:-10.10.10.1}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    sed -n '2,22p' "$0"
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo." >&2
    exit 1
fi

if ! id "$SAMBA_USER" >/dev/null 2>&1; then
    echo "Linux user does not exist: $SAMBA_USER" >&2
    exit 1
fi

echo "Installing Samba..."
if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y samba
    SMB_SERVICE="smbd"
elif command -v dnf >/dev/null 2>&1; then
    dnf install -y samba
    SMB_SERVICE="smb"
elif command -v yum >/dev/null 2>&1; then
    yum install -y samba
    SMB_SERVICE="smb"
else
    echo "Unsupported package manager. Install Samba manually." >&2
    exit 1
fi

mkdir -p "$SHARE_PATH"
chown -R "$SAMBA_USER":"$SAMBA_USER" "$SHARE_PATH"

SMB_CONF="/etc/samba/smb.conf"
if [[ -f "$SMB_CONF" ]]; then
    cp "$SMB_CONF" "${SMB_CONF}.bak.$(date +%Y%m%d%H%M%S)"
fi

if grep -q "^\[${SHARE_NAME}\]" "$SMB_CONF" 2>/dev/null; then
    echo "Section [$SHARE_NAME] already exists in $SMB_CONF; not appending."
    echo "Please review it manually."
else
    tee -a "$SMB_CONF" >/dev/null <<EOF

[$SHARE_NAME]
    path = $SHARE_PATH
    browseable = yes
    read only = no
    valid users = $SAMBA_USER
    create mask = 0664
    directory mask = 0775
EOF
    echo "Appended [$SHARE_NAME] to $SMB_CONF."
fi

echo
echo "Set the Samba password for $SAMBA_USER:"
smbpasswd -a "$SAMBA_USER"

systemctl enable --now "$SMB_SERVICE"
systemctl restart "$SMB_SERVICE"

echo
echo "Checking config..."
testparm -s >/dev/null

echo
echo "Firewall: allow $WINDOWS_IP -> TCP 445"
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    ufw allow from "$WINDOWS_IP" to any port 445 proto tcp
fi
if command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent \
        --add-rich-rule="rule family=\"ipv4\" source address=\"$WINDOWS_IP\" port port=\"445\" protocol=\"tcp\" accept"
    firewall-cmd --reload
fi

if command -v getenforce >/dev/null 2>&1 && [[ "$(getenforce)" == "Enforcing" ]]; then
    echo "SELinux is enforcing; applying Samba share context..."
    setsebool -P samba_export_all_rw on || true
    chcon -Rt samba_share_t "$SHARE_PATH" || true
fi

echo
echo "Done."
echo "Linux share: //10.10.10.2/$SHARE_NAME"
echo "Windows:     \\\\10.10.10.2\\$SHARE_NAME"
echo "User:        10.10.10.2\\$SAMBA_USER"
echo
echo "Verify on Windows:"
echo "  Test-NetConnection 10.10.10.2 -Port 445"
