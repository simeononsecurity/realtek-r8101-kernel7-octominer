#!/usr/bin/env bash
set -Eeuo pipefail

STATE=/var/lib/r8101-kernel7
KVER=${KVER:-$(uname -r)}
MODULE_DEST=/lib/modules/$KVER/updates/extra/r8101.ko

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

rm -f /etc/modprobe.d/r8101.conf
rm -f "$MODULE_DEST"
depmod -a "$KVER"
update-initramfs -u -k "$KVER"

modprobe -r r8101 2>/dev/null || true
modprobe r8169 2>/dev/null || true
nmcli device connect enp3s0 2>/dev/null || true

echo "Rollback complete. Verify with:"
echo "  ethtool -i enp3s0"