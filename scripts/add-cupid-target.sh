#!/usr/bin/env bash
# Install the xiaomi-cupid scaffold into a Project-Aloha checkout.
set -euo pipefail
ALOHA_ROOT="${1:-${ALOHA_ROOT:-}}"
[ -n "$ALOHA_ROOT" ] && [ -d "$ALOHA_ROOT/Platforms/WaipioPkg/Device/qcom-hdk8450" ] || {
  echo "Error: ALOHA_ROOT missing or not a mu_aloha_platforms checkout." >&2; exit 1; }

SRC="$(cd "$(dirname "$0")/.." && pwd)/firmware/aloha/xiaomi-cupid"
DST="$ALOHA_ROOT/Platforms/WaipioPkg/Device/xiaomi-cupid"
mkdir -p "$DST"
cp -R "$SRC/." "$DST/"

echo "Scaffold installed: $DST"
echo "Next: supply cupid.dtb + Binaries/cupid, then run:"
echo "  cd $ALOHA_ROOT && ./build_uefi.py -p WaipioPkg -d xiaomi-cupid"
