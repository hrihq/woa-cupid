#!/usr/bin/env bash
# Verify the inputs needed to drop cupid into a Mu-Silicium checkout.
set -euo pipefail
MU_ROOT="${1:-${MU_SILICIUM_ROOT:-}}"
[ -n "$MU_ROOT" ] && [ -d "$MU_ROOT" ] || { echo "Error: MU_SILICIUM_ROOT missing or invalid." >&2; exit 1; }

[ -f firmware/cupid_bootshim.S ] || { echo "Error: BootShim source missing." >&2; exit 1; }
[ -f firmware/config/cupid.toml ] || { echo "Error: cupid config missing." >&2; exit 1; }
[ -f Resources/DTBs/cupid.dtb ] || [ -f "$MU_ROOT/Resources/DTBs/cupid.dtb" ] || {
  echo "Error: user-supplied cupid.dtb missing." >&2; exit 1; }
[ -d "$MU_ROOT/Binaries/cupid" ] || {
  echo "Error: user-supplied Binaries/cupid (UEFIReader extract) missing." >&2; exit 1; }

echo "Integration prerequisites verified for cupid."
