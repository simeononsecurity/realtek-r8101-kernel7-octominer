#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ARCHIVE=${1:-"$ROOT/r8101-1.039.00.tar.bz2"}
STATE=/var/lib/r8101-kernel7
KVER=${KVER:-$(uname -r)}
MODULE_DEST=/lib/modules/$KVER/updates/extra/r8101.ko

[[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }
[[ -d /sys/bus/pci/devices/0000:03:00.0 ]] || echo "WARNING: expected X12 Ultra PCI address 0000:03:00.0 was not found"

"$ROOT/scripts/build.sh" "$ARCHIVE"
SRC=$(find "$ROOT/.build" -path '*/src/r8101.ko' -print -quit)
[[ -f "$SRC" ]] || { echo "Built module not found." >&2; exit 1; }

mkdir -p "$STATE" "$(dirname "$MODULE_DEST")"
cp -a /etc/modprobe.d/r8101.conf "$STATE/r8101.conf.bak" 2>/dev/null || true
cp -a /etc/default/grub "$STATE/grub.bak" 2>/dev/null || true
cp -a "$MODULE_DEST" "$STATE/r8101.ko.bak" 2>/dev/null || true

install -m 0644 "$SRC" "$MODULE_DEST"
depmod -a "$KVER"
cat > /etc/modprobe.d/r8101.conf <<'EOF'
# Prefer Realtek's official RTL810xE driver over the in-kernel r8169 driver.
blacklist r8169
EOF
update-initramfs -u -k "$KVER"

echo "Installed $MODULE_DEST"
echo "The live interface is not switched automatically by this script."
echo "Use a local console or alternate NIC, then run:"
echo "  ip link set enp3s0 down"
echo "  modprobe -r r8169"
echo "  modprobe r8101"
echo "  nmcli device connect enp3s0"