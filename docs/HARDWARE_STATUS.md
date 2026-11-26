# Hardware status

| Item | Status |
|---|---|
| `cargo test --workspace`, `cupidctl verify-*` | verified locally |
| `iasl`, `clang` BootShim compile, QEMU AAVMF `cupid-diag.efi` boot | verified in CI |
| ACPI MMIO bases / IRQs | provisional from SM8450 defaults + cupid framebuffer probe |
| Windows driver binding on cupid | unverified |
| Physical Xiaomi 12 boot | **UNTESTED** |

Do not flash to a daily-use device. Keep a way to restore the original
`xbl`/`abl` partitions.
