# Progress

## Readiness score (100 = Windows booted on device)

| Area | Weight | Earned |
|---|---:|---:|
| M1 source: BootShim + EDK2 + ACPI | 20 | 20 |
| Tooling, CI, Tier 1-3 | 20 | 20 |
| M2 deployment script + docs | 10 | 10 |
| M3 `cupidctl` dry-run | 10 | 10 |
| Aloha `xiaomi-cupid` scaffold | 10 | 10 |
| Vendor UEFI (`xbl` + `Binaries/cupid`) | 15 | 0 |
| `cupid.dtb` | 5 | 0 |
| Windows 11 ARM64 `install.wim` | 5 | 0 |
| Driver binaries | 3 | 0 |
| Tier 4 physical boot | 2 | 0 |
| **Total** | **100** | **70** |

Ceiling without owner-supplied assets: **70**. Boot score stays 0 until Tier 4.

## Wave 1

### M1 — UEFI platform / BootShim / ACPI — COMPLETE (source only)

- [x] BootShim source with 64-byte ARM64 header, `FD_BASE=0xA7100000`,
      `FD_SIZE=0x300000` (`firmware/cupid_bootshim.S`)
- [x] Minimal EDK2 overlay (`firmware/edk2/`)
- [x] DSDT + SSDT-CPU/USB/STORAGE/DISPLAY (`firmware/acpi/`)
- [x] Mu-Silicium integration prerequisites script
- [x] Aloha `xiaomi-cupid` target scaffold (`firmware/aloha/`, `scripts/add-cupid-target.sh`), tested against a stub checkout
- [x] DTB↔ACPI cross-check tool (`tools/check_dtb.py`, `--self-test` in CI)
- [x] boot.img assembler (`tools/build_boot_image.py`): gzip(BootShim||FD)||DTB, header v4 via Mu-Silicium mkbootimg; `--self-test` in CI
- [ ] `cupid_bootshim.efi` / AML binaries: produced by CI/releases, not tracked

### M2 — Drivers / deployment — IN PROGRESS

- [x] Driver inventory (`drivers/manifest.json`), chipset corrected to SM8450
- [x] `setup_cupid.ps1` staging + `pnputil`/`DISM` install + diag generation
- [x] Build/flash/install docs
- [ ] Licensed binaries for chipset, GPU, audio, Wi-Fi, camera

### E2E track

| Tier | Scope | Status |
|---|---|---|
| 1 | static config/manifest checks | PASS (`cupidctl verify-*`) |
| 2 | compile BootShim + ASL | PASS in CI |
| 3 | QEMU AAVMF boot of `cupid-diag.efi` | PASS in CI (run `45906870235`) |
| 4 | physical Xiaomi 12 boot | BLOCKED: no vendor blobs / Windows image |

CI: `https://github.com/hrihq/woa-cupid/actions/runs/45910919084` (green, termasuk M3 dry-run + DTB self-test).

## Checkpoint: Ready for boot-to-Windows

**NO — not ready.** Gates:

1. Owner-supplied `Binaries/cupid` from their own device (`UEFIReader`).
2. Owner-supplied `cupid.dtb` and Windows 11 ARM64 `install.wim`.
   Checklist: `docs/ASSET_COLLECTION.md`, `./tests/check-assets.ps1`.
3. Device-specific ACPI values validated against that DTB.
4. Tier 3 green and Tier 4 attempted on a device with backup/restore path.

## M3 — cupidctl dry-run tooling — DONE (no partition writes)

- [x] `flash-image --image <img> [--slot a|b]`: size/slot validation + plan;
      `--execute` refused.
- [x] `apply-acpi --aml <file>`: signature, declared length, checksum validation;
      `--execute` refused.
- [x] 4 unit tests; exercised against CI AML and bootshim artifacts.
- [ ] Real flashing/applying waits for owner-supplied boot image and device.
