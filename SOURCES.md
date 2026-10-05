# Sources and provenance

## Official Realtek source

- Product page: <https://www.realtek.com/en/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-pci-express-software>
- Direct endpoint: <https://www.realtek.com/Download/ToDownload?type=direct&downloadid=3614>
- Driver: `r8101` version `1.039.00`
- Realtek update date: `2024-06-03`
- Official page's stated kernel range: up to `6.1`
- Local archive SHA-256: `e64e1738e71d6717dd844bf771fea4691edae63e92d7d03bb5ad2ef08e56e72b`

## Hardware identification

The target X12 Ultra device was identified as:

```text
10ec:8136 Realtek RTL810xE PCI Express Fast Ethernet controller
```

The source contains the matching PCI alias:

```text
pci:v000010ECd00008136sv*sd*bc*sc*i*
```

## Compatibility patch provenance

The patch in `patches/kernel-7-plus.patch` was developed against Ubuntu's
`7.0.0-34-generic` headers. It changes only timer API compatibility and does
not alter the driver's hardware initialization or DMA allocation logic.

## Related but not used

The archived repository below contains an older `r8101` 1.035.03 source tree.
It is not used by this project:

- <https://github.com/adithya2306/realtek-r8101-linux-driver>

It was archived on 2021-02-21 and does not build on kernel 7.0 without many
additional compatibility changes.