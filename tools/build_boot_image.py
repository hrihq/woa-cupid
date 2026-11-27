#!/usr/bin/env python3
"""Assemble a cupid boot.img from owner-supplied firmware pieces.

Layout (matches firmware/config/cupid.toml, header v4):
    kernel = gzip(BootShim.bin || uefi_fd.bin) || cupid.dtb
    boot.img = mkbootimg(kernel, header_version=4, base=0xA7100000)

Uses Mu-Silicium's mkbootimg.py for the final pack when --mkbootimg is given.
Without it the kernel is still assembled and validated (dry-run). Stdlib only.
Never flashes anything.
"""
import argparse
import gzip
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

DTB_MAGIC = 0xD00DFEED
GZIP_MAGIC = b"\x1f\x8b"
HEADER_V4 = 4


def check_dtb(data):
    if len(data) < 40 or struct.unpack_from(">I", data)[0] != DTB_MAGIC:
        raise ValueError("bad DTB magic (expected D00DFEED)")


def assemble_kernel(bootshim, fd, dtb):
    check_dtb(dtb)
    raw = bootshim + fd
    if not raw:
        raise ValueError("empty BootShim/FD")
    kernel = gzip.compress(raw, mtime=0)
    return kernel + dtb, kernel, len(raw)


def pack(args, kernel_file, output):
    if not args.mkbootimg:
        print(f"DRY-RUN: kernel assembled ({kernel_file.stat().st_size} bytes); "
              "pass --mkbootimg <Mu-Silicium/Resources/Scripts/mkbootimg.py> to pack")
        return
    cmd = [
        sys.executable, str(args.mkbootimg),
        "--kernel", str(kernel_file),
        "--output", str(output),
        "--header_version", str(HEADER_V4),
        "--base", hex(args.base),
        "--kernel_offset", hex(args.kernel_offset),
        "--pagesize", str(args.pagesize),
        "--tags_offset", "0x00000100",
        "--cmdline", "",
    ]
    subprocess.run(cmd, check=True)
    data = output.read_bytes()
    if data[:8] != b"ANDROID!":
        raise ValueError("boot.img missing ANDROID! magic")
    if struct.unpack_from("<I", data, 28)[0] != HEADER_V4:
        raise ValueError("boot.img header version != 4")
    if struct.unpack_from("<I", data, 8)[0] != kernel_file.stat().st_size:
        raise ValueError("boot.img kernel size mismatch")
    print(f"PACKED: {output} ({len(data)} bytes, header v4)")


def self_test():
    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        bootshim = b"CUPID_BOOTSHIM" * 8
        fd = b"UEFI_FD_PAYLOAD" * 32
        dtb = bytearray(64)
        struct.pack_into(">I", dtb, 0, DTB_MAGIC)
        kernel, gz, raw = assemble_kernel(bootshim, fd, dtb)
        assert gz[:2] == GZIP_MAGIC, "kernel not gzip"
        assert gzip.decompress(gz) == bootshim + fd, "gzip roundtrip failed"
        assert kernel.endswith(dtb), "DTB not appended"
        assert raw == len(bootshim) + len(fd)
        kf = d / "kernel"
        kf.write_bytes(kernel)
        pack(argparse.Namespace(mkbootimg=None, base=0, kernel_offset=0,
                                pagesize=4096), kf, d / "boot.img")
    print("BOOT_IMAGE_SELFTEST_PASS")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--bootshim", type=Path, help="built BootShim.bin")
    p.add_argument("--fd", type=Path, help="owner-built UEFI FD binary")
    p.add_argument("--dtb", type=Path, help="owner-supplied cupid.dtb")
    p.add_argument("--output", type=Path, default=Path("firmware/out/boot.img"))
    p.add_argument("--mkbootimg", type=Path, help="Mu-Silicium mkbootimg.py")
    p.add_argument("--base", type=int, default=0xA7100000)
    p.add_argument("--kernel-offset", type=int, default=0x00080000)
    p.add_argument("--pagesize", type=int, default=4096)
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args()

    if args.self_test:
        self_test()
        return 0

    for name in ("bootshim", "fd", "dtb"):
        if not getattr(args, name):
            p.error(f"--{name} required")
    try:
        kernel, _, raw = assemble_kernel(
            args.bootshim.read_bytes(), args.fd.read_bytes(),
            args.dtb.read_bytes())
    except Exception as exc:
        print(f"BOOT_IMAGE_FAIL: {exc}")
        return 1

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=args.output.parent, delete=False) as f:
        f.write(kernel)
        kf = Path(f.name)
    try:
        pack(args, kf, args.output)
    finally:
        kf.unlink(missing_ok=True)
    print(f"kernel: gzip({raw} bytes) + DTB appended")
    return 0


if __name__ == "__main__":
    sys.exit(main())
