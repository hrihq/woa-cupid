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
PART="$DISK@@1M"
dd if=/dev/zero of="$DISK" bs=1M count=16 status=none
sgdisk -n 1:1M:-1M -t 1:ef00 -c 1:WOA "$DISK" >/dev/null
LOOP="$(sudo losetup -fP --show "$DISK")"
sudo mkfs.vfat -F 16 -n WOA "${LOOP}p1" >/dev/null
sudo losetup -d "$LOOP"
mmd -i "$PART" ::/EFI
mmd -i "$PART" ::/EFI/BOOT
mcopy -i "$PART" -o "$EFI" ::/EFI/BOOT/BOOTAA64.EFI
printf '\\EFI\\BOOT\\BOOTAA64.EFI\r\n' > firmware/out/startup.nsh
mcopy -i "$PART" -o firmware/out/startup.nsh ::/startup.nsh

timeout 60s qemu-system-aarch64 -M virt -cpu cortex-a57 -m 512 -nographic \
  -nodefaults -display none -serial mon:stdio -bios "$BV" \
  -drive if=none,file="$DISK",format=raw,id=disk \
  -device qemu-xhci,id=xhci -device usb-storage,bus=xhci.0,drive=disk 2>&1 | tee "$LOG" || true

grep -q 'CUPID_DIAG_OK' "$LOG" || { echo "QEMU boot marker absent" >&2; exit 1; }
echo "E2E_TIER3_PASS"
