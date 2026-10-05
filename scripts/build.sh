#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ARCHIVE=${1:-"$ROOT/r8101-1.039.00.tar.bz2"}
EXPECTED_SHA256=e64e1738e71d6717dd844bf771fea4691edae63e92d7d03bb5ad2ef08e56e72b
BUILD_ROOT=${BUILD_ROOT:-"$ROOT/.build"}

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -f "$ARCHIVE" ]] || die "archive not found: $ARCHIVE"
command -v sha256sum >/dev/null || die "sha256sum is required"
command -v tar >/dev/null || die "tar is required"
command -v make >/dev/null || die "make is required"
command -v gcc >/dev/null || die "gcc is required"

KVER=${KVER:-$(uname -r)}
KDIR=${KDIR:-/lib/modules/$KVER/build}
[[ -e "$KDIR/Makefile" ]] || die "kernel headers not found: $KDIR"

actual=$(sha256sum "$ARCHIVE" | awk '{print $1}')
[[ "$actual" == "$EXPECTED_SHA256" ]] || die "archive checksum mismatch: $actual"

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT"
tar -xjf "$ARCHIVE" -C "$BUILD_ROOT"
SRC=$(find "$BUILD_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'r8101-*' -print -quit)
[[ -n "$SRC" ]] || die "could not find extracted r8101 source"

patch -d "$SRC" -p1 < "$ROOT/patches/kernel-7-plus.patch"
make -C "$SRC/src" clean
make -C "$SRC/src" KVER="$KVER" KERNELDIR="$KDIR" modules

MODULE="$SRC/src/r8101.ko"
[[ -f "$MODULE" ]] || die "module was not produced"
modinfo "$MODULE" | grep -q 'version: *1.039.00' || die "unexpected driver version"
modinfo "$MODULE" | grep -q 'vermagic: *'"$KVER" || die "module vermagic does not match $KVER"
modinfo -F alias "$MODULE" | grep -qi '10ECd00008136' || die "module lacks PCI alias 10ec:8136"

echo "Build succeeded"
echo "Source: $SRC"
echo "Module: $MODULE"
modinfo "$MODULE" | grep -E '^(version|vermagic|alias):' | head -8