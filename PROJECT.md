# Project survey (reconstructed)

The prior Step 0 `PROJECT.md` was not present in the workspace; this is the
survey needed to continue, derived from local `hakios-device-cupid` /
`Mu-Silicium` references and the WOA-Project upstreams.

## Target

| Item | Value |
|---|---|
| Device | Xiaomi 12, codename `cupid` |
| SoC | Snapdragon 8 Gen 1, `SM8450` / `waipio` |
| Target OS | Windows 11 ARM64 (latest available build) |
| UEFI FD | base `0xA7100000`, size `0x300000` (measured from `uefi_a.img` PT_LOAD) |
| BootShim | 64-byte ARM64 header + FD copy loop, branches to `FD_BASE` |
| Panel | 1080x2400, splash/framebuffer at `0xB8000000` |

## Wrong assumptions corrected

- `msm8998` is Snapdragon 835, **not** cupid. Use `SM8450` everywhere.
- No public Windows driver set is proven on cupid. Upstream Waipio BSP has
  no binaries in-tree. All driver work is inventory + deployment tooling.

## Sources

- `https://github.com/WOA-Project/windows_silicon_qcom_waipio` (SM8450 BSP, empty bin set)
- `https://github.com/WOA-Project/Qualcomm-Reference-Drivers` (reference CABs)
- `https://github.com/WOA-Project/acpi_oem_qcom_common` (ACPI patterns)
- `https://github.com/Project-Silicium/Mu-Silicium` (BootShim, DSC/FDF patterns)
- local `hakios-device-cupid/uefi` (cupid memory map, BootShim probes, DTB)

## Constraints

- PoC only. No vendor blobs, no Windows image, nodevice flashing here.
- Binaries are build artifacts or release assets, never tracked in git.
- Physical-hardware status: **UNTESTED**.
