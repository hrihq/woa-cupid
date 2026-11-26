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
| 3 | QEMU AAVMF boot of `cupid-diag.efi` | CI |
| 4 | physical Xiaomi 12 boot | BLOCKED: no vendor blobs / Windows image |

## Checkpoint: Ready for boot-to-Windows

**NO — not ready.** Gates:

1. Owner-supplied `Binaries/cupid` from their own device (`UEFIReader`).
2. Owner-supplied `cupid.dtb` and Windows 11 ARM64 `install.wim`.
3. Device-specific ACPI values validated against that DTB.
4. Tier 3 green and Tier 4 attempted on a device with backup/restore path.

## M3 (planned)

- `cupidctl flash-image --image <img>` and `cupidctl apply-acpi --aml <file>`:
  placeholders return `NOT IMPLEMENTED`.
