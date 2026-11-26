#!/usr/bin/env bash
# Tier 1-2 offline E2E. Safe without vendor blobs or hardware.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="firmware/out"
mkdir -p "$OUT"

if command -v cargo >/dev/null; then
  cargo test --workspace --quiet
  cargo run --quiet -p cupidctl -- verify-platform --root .
  cargo run --quiet -p cupidctl -- verify-drivers --root .
fi

if command -v clang >/dev/null && command -v llvm-objcopy >/dev/null; then
  clang --target=aarch64-linux-gnu -c firmware/cupid_bootshim.S -o "$OUT/cupid_bootshim.elf" \
    -DREQUIRES_KERNEL_HEADER=1 -DFD_BASE=0xA7100000 -DFD_SIZE=0x300000
  llvm-objcopy -O binary "$OUT/cupid_bootshim.elf" "$OUT/cupid_bootshim.bin"
  echo "BootShim compiled"
else
  echo "clang/llvm-objcopy missing; BootShim compile skipped" >&2
fi

if command -v iasl >/dev/null; then
  for asl in firmware/acpi/*.asl; do
    name="$(basename "$asl" .asl)"
    iasl -ta -p "$OUT/$name" "$asl"
  done
  echo "ACPI compiled"
else
  echo "iasl missing; AML compile skipped" >&2
fi

echo "E2E_TIER1_2_PASS"
