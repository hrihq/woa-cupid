# Progress

## Wave 1

### M1 — UEFI platform / BootShim / ACPI — COMPLETE (source only)

- [x] BootShim source with 64-byte ARM64 header, `FD_BASE=0xA7100000`,
      `FD_SIZE=0x300000` (`firmware/cupid_bootshim.S`)
- [x] Minimal EDK2 overlay (`firmware/edk2/`)
- [x] DSDT + SSDT-CPU/USB/STORAGE/DISPLAY (`firmware/acpi/`)
- [x] Mu-Silicium integration prerequisites script
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

CI: `https://github.com/hrihq/woa-cupid/actions/runs/45907554415` (green, termasuk M3 dry-run).

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
