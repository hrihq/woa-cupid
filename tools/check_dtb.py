#!/usr/bin/env python3
"""Cross-check cupid DTB MMIO/IRQ against this repo's ACPI ASL.

stdlib only. No device or vendor blob needed for --self-test.
"""
import argparse
import struct
import sys
from pathlib import Path

MAGIC = 0xD00DFEED
BEGIN_NODE, END_NODE, PROP, NOP, END = 1, 2, 3, 4, 9

# name, compatible fragment, ASL file, MMIO base, IRQ (None = skip)
CHECKS = [
    ("USB", "xhci", "SSDT-USB.asl", 0x0A000000, 0x9D),
    ("UFS", "ufshc", "SSDT-STORAGE.asl", 0x01D84000, 0x86),
    ("DISPLAY", "mdss", "SSDT-DISPLAY.asl", 0x0AE00000, None),
]


def align4(n):
    return (n + 3) & ~3


def parse_dtb(data):
    if len(data) < 40 or struct.unpack_from(">I", data)[0] != MAGIC:
        raise ValueError("bad DTB magic")
    _, total, off_struct, off_strings, _, _, _, _, _, size_struct = struct.unpack_from(">10I", data)
    if total > len(data) or off_struct + size_struct > len(data):
        raise ValueError("truncated DTB")
    strings = data[off_strings:off_strings + total - off_strings]
    pos, stack, nodes = off_struct, [], []

    def string_at(offset):
        end = strings.find(b"\0", offset)
        return strings[offset:end].decode("utf-8", "replace")

    while pos < off_struct + size_struct:
        token = struct.unpack_from(">I", data, pos)[0]
        pos += 4
        if token == BEGIN_NODE:
            end = data.index(b"\0", pos)
            name = data[pos:end].decode("utf-8", "replace")
            pos = align4(end + 1)
            stack.append({"name": name, "props": {}})
        elif token == PROP:
            length, nameoff = struct.unpack_from(">II", data, pos)
            pos += 8
            payload = data[pos:pos + length]
            pos = align4(pos + length)
            if stack:
                stack[-1]["props"][string_at(nameoff)] = payload
        elif token == END_NODE:
            if stack:
                nodes.append(stack.pop())
        elif token == NOP:
            continue
        elif token == END:
            break
        else:
            raise ValueError(f"unknown DTB token {token}")
    return nodes


def node_ints(payload):
    return [struct.unpack_from(">I", payload, i)[0] for i in range(0, len(payload) - 3, 4)]


def compatible_text(node):
    raw = node["props"].get("compatible", b"")
    return raw.decode("utf-8", "replace")


def make_self_test_dtb():
    strings = bytearray()
    offsets = {}

    def add_string(text):
        if text not in offsets:
            offsets[text] = len(strings)
            strings.extend(text.encode() + b"\0")
        return offsets[text]

    struct_block = bytearray()

    def prop(name, payload):
        struct_block.extend(struct.pack(">III", PROP, len(payload), add_string(name)))
        struct_block.extend(payload)
        struct_block.extend(b"\0" * (align4(len(payload)) - len(payload)))

    def begin(name):
        raw = name.encode() + b"\0"
        struct_block.extend(struct.pack(">I", BEGIN_NODE))
        struct_block.extend(raw)
        struct_block.extend(b"\0" * (align4(len(raw)) - len(raw)))

    def end():
        struct_block.extend(struct.pack(">I", END_NODE))

    begin("")
    prop("compatible", b"qcom,sm8450-cupid\0")
    begin("soc")
    for compat, base, irq in [
        ("qcom,sm8450-xhci", 0x0A000000, 0x9D),
        ("qcom,sm8450-ufshc", 0x01D84000, 0x86),
        ("qcom,sm8450-mdss", 0x0AE00000, None),
    ]:
        begin("bus@0")
        prop("compatible", compat.encode() + b"\0")
        reg = struct.pack(">4I", 0, base, 0, 0x10000)
        prop("reg", reg)
        if irq is not None:
            prop("interrupts", struct.pack(">I", irq))
        end()
    end()
    end()
    struct_block.extend(struct.pack(">I", END))

    header_size = 40
    reserve = b"\0" * 16
    off_struct = header_size + len(reserve)
    off_strings = off_struct + len(struct_block)
    total = off_strings + len(strings)
    header = struct.pack(">10I", MAGIC, total, off_struct, off_strings,
                         header_size, 17, 16, 0, len(strings), len(struct_block))
    return header + reserve + bytes(struct_block) + bytes(strings)


def run_checks(data, asl_dir):
    nodes = parse_dtb(data)
    problems = []
    for name, fragment, asl_name, base, irq in CHECKS:
        asl = (asl_dir / asl_name).read_text(encoding="utf-8", errors="replace")
        if f"0x{base:08X}".upper() not in asl.upper():
            problems.append(f"{name}: ASL missing MMIO 0x{base:08X}")
        matches = [n for n in nodes if fragment in compatible_text(n)]
        if not matches:
            problems.append(f"{name}: DTB node with '{fragment}' missing")
            continue
        regs = [v for n in matches for v in node_ints(n["props"].get("reg", b""))]
        if base not in regs:
            problems.append(f"{name}: DTB reg lacks 0x{base:08X}")
        if irq is not None:
            irqs = [v for n in matches for v in node_ints(n["props"].get("interrupts", b""))]
            if irq not in irqs:
                problems.append(f"{name}: DTB IRQ lacks 0x{irq:02X}")
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dtb", type=Path, help="owner-supplied cupid.dtb")
    parser.add_argument("--asl-dir", type=Path, default=Path("firmware/acpi"))
    parser.add_argument("--self-test", action="store_true", help="use a synthetic DTB")
    args = parser.parse_args()

    if args.self_test:
        data = make_self_test_dtb()
    elif args.dtb:
        data = args.dtb.read_bytes()
    else:
        parser.error("--dtb or --self-test required")

    try:
        problems = run_checks(data, args.asl_dir)
    except Exception as exc:
        print(f"DTB_ACPI_FAIL: {exc}")
        return 1
    if problems:
        print("DTB_ACPI_FAIL: " + "; ".join(problems))
        return 1
    print(f"DTB_ACPI_MATCH: {len(CHECKS)} checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
