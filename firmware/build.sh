#!/usr/bin/env bash
# Build the parts that can be built without device-owned firmware blobs.
set -euo pipefail
cd "$(dirname "$0")"
OUT="${OUT:-out}"
mkdir -p "$OUT"

command -v clang >/dev/null || { echo "clang missing; see docs/TOOLCHAIN.md" >&2; exit 1; }
clang --target=aarch64-linux-gnu -c cupid_bootshim.S -o "$OUT/cupid_bootshim.elf" \
  -DREQUIRES_KERNEL_HEADER=1 -DFD_BASE=0xA7100000 -DFD_SIZE=0x300000
llvm-objcopy -O binary "$OUT/cupid_bootshim.elf" "$OUT/cupid_bootshim.bin"

if command -v iasl >/dev/null; then
  for asl in acpi/*.asl; do
    name="$(basename "$asl" .asl)"
    iasl -ta -p "$OUT/$name" "$asl"
  done
else
  echo "iasl missing; skipped AML" >&2
fi

echo "built: $OUT/cupid_bootshim.bin"
