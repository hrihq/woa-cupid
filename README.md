# woa-cupid

Windows-on-ARM64 proof of concept for Xiaomi 12 (`cupid`, **SM8450 / waipio**).

> **Status: build/verify scaffold, not a bootable Windows image.**
> Physical cupid hardware has **not** been tested. Vendor UEFI drivers, a
> licensed Windows 11 ARM64 image and device-specific driver binaries must be
> supplied by the owner. Nothing here redistributes them.

## Layout

| Path | Contents |
|---|---|
| `firmware/cupid_bootshim.S` | BootShim source (FD copy + branch) |
| `firmware/acpi/*.asl` | DSDT + CPU/USB/storage/display SSDTs |
| `firmware/edk2/` | minimal EDK2 overlay (DEC/DSC/FDF/INF) |
| `firmware/out/` | build artifacts, gitignored |
| `drivers/manifest.json` | driver inventory, no binaries |
| `tools/cupidctl/` | placeholder control CLI (`verify-*` implemented) |
| `tools/cupid-diag/` | UEFI marker app for QEMU smoke test |
| `setup_cupid.ps1` | driver staging/install + diag generation |
| `tests/` | offline E2E and QEMU AAVMF smoke test |

## Build & verify

See [docs/BUILD_AND_VERIFY.md](docs/BUILD_AND_VERIFY.md).

```sh
cargo test --workspace
bash tests/run-e2e.sh
```

CI runs the same checks, compiles the ACPI tables and BootShim, builds
`cupid-diag.efi`, and boots it under QEMU AAVMF. A green CI means the
toolchain and emulator path work. **It does not mean Windows boots on cupid.**

## Flash & boot

See [docs/INSTALL_WINDOWS.md](docs/INSTALL_WINDOWS.md). Flashing unofficial
firmware can permanently damage the device. Back up `xbl`, `abl` and the
persistent partitions before any write.

## Hardware status

See [docs/HARDWARE_STATUS.md](docs/HARDWARE_STATUS.md) and
[progress.md](progress.md).
