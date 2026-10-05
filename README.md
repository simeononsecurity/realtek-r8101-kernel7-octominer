# Realtek `r8101` for Kernel 7+ on the Octominer X12 Ultra

This repository documents and automates the compatibility work required to use
Realtek's official `r8101` driver with the **Realtek RTL810xE / RTL8105E Fast
Ethernet PCIe controller** used by the Octominer X12 Ultra rig.

## Target hardware

| Item | Value |
| --- | --- |
| Controller | Realtek RTL810xE / RTL8105E |
| PCI vendor/device ID | `10ec:8136` |
| Rig | Octominer X12 Ultra |
| Tested interface | `enp3s0` |
| Tested PCI address | `0000:03:00.0` |
| Tested link | 100 Mb/s full duplex |

The target device is a Fast Ethernet controller. This is **not** a replacement
for the Realtek gigabit `r8168` driver and is not intended for RTL8111/RTL8168
controllers.

## Target operating systems

The tested system was Ubuntu 24.04 running:

```text
Linux 7.0.0-34-generic x86_64
```

The official Realtek `r8101` 1.039.00 source advertises support only through
kernel 6.1. This repository adds a small compatibility patch for kernel 7.0
and newer kernels where the affected timer APIs are available. The scripts
refuse to claim compatibility without compiling against the running kernel's
headers.

This may also apply to equivalent Ubuntu installations using kernel 7.x or
newer, but each target kernel must be built and tested independently.

## Why this exists

The X12 Ultra's onboard RTL8105E was using Ubuntu's in-kernel `r8169` driver.
During the failure investigation the system recorded DMA/IOMMU faults from
PCI device `03:00.0`, followed by loss of DHCP/default-route state. The
official `r8101` driver is the correct Realtek driver family for this 100 Mb/s
controller, but the official 1.039.00 source did not compile unchanged on
kernel 7.0.

The compatibility patch:

1. Includes the kernel timer header explicitly.
2. Replaces removed `from_timer()` usage with `container_of()`.
3. Uses kernel 6.15+ `timer_delete_sync()` while retaining
   `del_timer_sync()` for older kernels.

No DMA behavior was rewritten by this patch. A successful build is not proof
that every kernel, motherboard, BIOS, IOMMU configuration, or cable/switch
combination is stable.

## Upstream source

Obtain the official archive from Realtek:

```text
https://www.realtek.com/Download/ToDownload?type=direct&downloadid=3614
```

Expected archive:

```text
r8101-1.039.00.tar.bz2
```

Expected SHA-256:

```text
e64e1738e71d6717dd844bf771fea4691edae63e92d7d03bb5ad2ef08e56e72b
```

Realtek's endpoint may return an HTML CAPTCHA/maintenance page instead of the
archive. Do not extract or build a file unless `file` identifies it as bzip2
data and the checksum matches.

## Quick start

Copy the official archive into this repository or pass its path explicitly:

```bash
./scripts/build.sh /path/to/r8101-1.039.00.tar.bz2
```

The build script:

- verifies the archive checksum;
- verifies kernel headers and build tools;
- extracts into a temporary build directory;
- applies `patches/kernel-7-plus.patch`;
- builds against `uname -r`;
- validates vermagic and PCI alias `10ec:8136`.

Install from a local console or with an alternate management path:

```bash
sudo ./scripts/install.sh /path/to/r8101-1.039.00.tar.bz2
```

The installer backs up the active driver configuration, installs the module,
blacklists `r8169`, and refreshes initramfs. It intentionally does **not**
switch the live device automatically, because doing so over the only SSH
connection can strand the machine. Use a separate Intel i210/i350 NIC, USB
Ethernet adapter, IPMI/KVM, or local console for the live switch.

Rollback:

```bash
sudo ./scripts/rollback.sh
```

## Verification

After installation, verify:

```bash
ethtool -i enp3s0
lsmod | grep -E '^(r8101|r8169)'
ip route
ping -c 5 192.168.1.1
journalctl -k -b | grep -Ei 'r8101|r8169|DMAR|IOMMU|enp3s0'
```

Expected driver output includes:

```text
driver: r8101
version: 1.039.00
bus-info: 0000:03:00.0
```

The module built in the original X12 Ultra test was unsigned and caused the
normal kernel warning:

```text
module verification failed: signature and/or required key missing
```

For systems with Secure Boot or enforced module signatures, sign the module
with an enrolled Machine Owner Key before installation. Do not disable Secure
Boot as an unattended workaround.

## Safety and limitations

- The archive is Realtek's source; this repository contains the compatibility
  patch and automation, not a redistributed copy of the source.
- The scripts do not disable IOMMU. If DMA faults continue under `r8101`, use
  a separate NIC or investigate the motherboard/PCIe/IOMMU path.
- The driver is for `10ec:8136` RTL810xE-family hardware. Confirm with
  `lspci -nn` before installation.
- Do not use the archived GitHub `r8101` 1.035.03 tree for kernel 7+.
- The original Realtek `autorun.sh` is intentionally not used because it
  unloads and renames distro modules without providing a safe remote rollback.

## License and attribution

The driver source remains Copyright © 2024 Realtek Semiconductor Corp. and is
distributed by Realtek under the license included in the official archive.
This repository's scripts and patch are provided under the MIT License in
`LICENSE`. Review the upstream `readme` and source license before redistributing
the driver source or binaries.