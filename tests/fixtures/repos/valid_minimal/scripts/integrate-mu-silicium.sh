#!/usr/bin/env bash
set -euo pipefail

MU_ROOT="${1:-${MU_SILICIUM_ROOT:-}}"
if [ -z "$MU_ROOT" ] || [ ! -d "$MU_ROOT" ]; then
  echo "Error: Mu-Silicium root directory missing or invalid." >&2
  exit 1
fi

if [ ! -d "$MU_ROOT/Binaries/cupid" ]; then
  echo "Error: Missing user-supplied Binaries/cupid (extract via UEFIReader)." >&2
  exit 1
fi

if [ ! -f "Resources/DTBs/cupid.dtb" ] && [ ! -f "$MU_ROOT/Resources/DTBs/cupid.dtb" ]; then
  echo "Error: Missing user-supplied cupid.dtb." >&2
  exit 1
fi

echo "Integration prerequisites verified for cupid."
