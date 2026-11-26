#!/usr/bin/env bash
# Tier 3: boot a minimal UEFI app in QEMU AAVMF. Not a phone boot.
set -euo pipefail
cd "$(dirname "$0")/.."
EFI="firmware/out/cupid-diag.efi"
LOG="firmware/out/qemu.log"
[ -f "$EFI" ] || { echo "missing $EFI" >&2; exit 1; }
BV="/usr/share/qemu-efi-aarch64/QEMU_EFI.fd"
[ -f "$BV" ] || BV="/usr/share/AAVMF/AAVMF_CODE.fd"
[ -f "$BV" ] || { echo "AAVMF firmware missing" >&2; exit 1; }

DISK="firmware/out/bootdisk.img"
dd if=/dev/zero of="$DISK" bs=1M count=16 status=none
mformat -i "$DISK" -F ::
mmd -i "$DISK" ::/EFI
mmd -i "$DISK" ::/EFI/BOOT
mcopy -i "$DISK" -o "$EFI" ::/EFI/BOOT/BOOTAA64.EFI

timeout 60s qemu-system-aarch64 -M virt -cpu cortex-a57 -m 512 -nographic \
  -nodefaults -display none -serial mon:stdio -bios "$BV" \
  -drive if=none,file="$DISK",format=raw,id=disk \
  -device usb-storage,drive=disk 2>&1 | tee "$LOG" || true

grep -q 'CUPID_DIAG_OK' "$LOG" || { echo "QEMU boot marker absent" >&2; exit 1; }
echo "E2E_TIER3_PASS"
