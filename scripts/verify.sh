#!/usr/bin/env bash
set -Eeuo pipefail

IFACE=${1:-enp3s0}
GATEWAY=${2:-$(ip -4 route show default | awk 'NR==1 {print $3}')}

echo '=== PCI ==='
lspci -nn | grep -Ei 'Ethernet|Realtek' || true
echo '=== DRIVER ==='
ethtool -i "$IFACE"
echo '=== LINK ==='
ethtool "$IFACE" | grep -E 'Speed|Duplex|Link detected'
echo '=== ROUTE ==='
ip -4 route
if [[ -n "$GATEWAY" ]]; then
  echo '=== GATEWAY TEST ==='
  ping -4 -c 5 -W 1 "$GATEWAY"
fi
echo '=== RECENT KERNEL LOG ==='
journalctl -k -b --no-pager | grep -Ei 'r8101|r8169|DMAR|IOMMU|NETDEV WATCHDOG|enp3s0' | tail -100 || true