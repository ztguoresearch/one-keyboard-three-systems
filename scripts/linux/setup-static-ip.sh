#!/usr/bin/env bash
#
# Fix the direct-link IP on Linux with NetworkManager.
#
# Usage:
#   sudo ./setup-static-ip.sh [interface] [cidr]
#
# Examples:
#   sudo ./setup-static-ip.sh eno1 10.10.10.2/24
#
# Notes:
#   - No default gateway is set on purpose.
#   - Internet should keep using Wi-Fi or another interface.
#
set -euo pipefail

IFACE="${1:-eno1}"
ADDR="${2:-10.10.10.2/24}"

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    sed -n '2,20p' "$0"
    exit 0
fi

if ! command -v nmcli >/dev/null 2>&1; then
    echo "nmcli not found. This script assumes NetworkManager." >&2
    echo "For netplan, edit /etc/netplan/*.yaml instead." >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo." >&2
    exit 1
fi

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "Interface not found: $IFACE" >&2
    echo "Available interfaces:" >&2
    ip -br link >&2
    exit 1
fi

CON="$(nmcli -t -f NAME,DEVICE con show | awk -F: -v d="$IFACE" '$2 == d { print $1; exit }')"

if [[ -z "${CON}" ]]; then
    echo "No NetworkManager connection for $IFACE; creating 'direct'."
    nmcli con add type ethernet ifname "$IFACE" con-name direct ip4 "$ADDR"
    CON="direct"
fi

echo "Configuring connection '$CON' on $IFACE -> $ADDR (no gateway)"
nmcli con mod "$CON" \
    ipv4.method manual \
    ipv4.addresses "$ADDR" \
    ipv4.gateway "" \
    ipv4.never-default yes

nmcli con up "$CON"

echo
echo "Result:"
ip -br addr show "$IFACE"
ip route | grep "$IFACE" || true

echo
echo "Test from this machine:"
echo "  ping -c 3 10.10.10.1"
