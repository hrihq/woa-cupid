# woa-cupid (Minimal Test Fixture)

Windows on ARM exploration for Xiaomi 12 (`cupid`, SM8450 / Waipio).

## Verification & Hardware Readiness
- **Verified Locally**: `cargo test --workspace`, `cupidctl verify-platform --root .`, `cupidctl verify-drivers --root .`, `tests/run-e2e.ps1`.
- **Verified in CI**: `iasl`, `clang` `BootShim.S`, `qemu-system-aarch64` + `AAVMF` boot of `cupid-diag.efi`, `tests/run-e2e.sh`.
- **User-Supplied Proprietary Blobs (Not Redistributed)**: `Binaries/cupid` via `UEFIReader`, `cupid.dtb`, Windows 11 ARM64 `install.wim`, and `WOA-Project/windows_silicon_qcom_waipio`.
- **UNTESTED on Physical Hardware**: Booting Windows 11 on physical Xiaomi 12 (`cupid`) hardware is currently UNTESTED.

See [docs/HARDWARE_STATUS.md](docs/HARDWARE_STATUS.md), [docs/BUILD_AND_VERIFY.md](docs/BUILD_AND_VERIFY.md), and [docs/INSTALL_WINDOWS.md](docs/INSTALL_WINDOWS.md).
