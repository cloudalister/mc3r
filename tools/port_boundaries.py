#!/usr/bin/env python3
"""Port missing function boundaries from the alpha MC.MAP to retail.

Only intervals bracketed by two already-matched anchors with the same relocation
delta are considered.  Candidates are emitted only when they are aligned, live
inside retail .text, split an existing generated owner, fit inside that owner,
and are not already known by the Ghidra export.
"""

from __future__ import annotations

import argparse
import bisect
import csv
import re
import struct
import sys
from dataclasses import dataclass
from pathlib import Path


MAP_SECTION_RE = re.compile(r"^([0-9a-f]{8}) ([0-9a-f]{8})\s+\d+ (\.\S+)\s*$")
MAP_SYMBOL_RE = re.compile(r"^([0-9a-f]{8}) ([0-9a-f]{8})\s+0 \s+(\S.*?)\s*$")
OWNER_FUNCTION_RE = re.compile(r"^// Function:\s*(.*?)\s*$", re.MULTILINE)
OWNER_RANGE_RE = re.compile(
    r"^// Address:\s*0x([0-9a-fA-F]+)\s*-\s*0x([0-9a-fA-F]+)\s*$",
    re.MULTILINE,
)


@dataclass(frozen=True)
class AlphaFunction:
    address: int
    size: int
    name: str


@dataclass(frozen=True)
class Anchor:
    alpha_address: int
    retail_address: int

    @property
    def delta(self) -> int:
        return self.retail_address - self.alpha_address


@dataclass(frozen=True)
class AddressRange:
    start: int
    end: int
    name: str


@dataclass(frozen=True)
class Candidate:
    alpha: AlphaFunction
    retail_address: int
    delta: int
    anchor_lo: Anchor
    anchor_hi: Anchor
    owner: AddressRange | None = None


def parse_int(value: str) -> int:
    return int(value.strip(), 0)


def load_alpha_functions(map_path: Path) -> list[AlphaFunction]:
    lines = map_path.read_text(encoding="utf-8", errors="replace").splitlines()
    text_ranges: list[tuple[int, int]] = []

    for line in lines:
        match = MAP_SECTION_RE.match(line)
        if match and not line.startswith("        ") and match.group(3).startswith(".text"):
            start = int(match.group(1), 16)
            text_ranges.append((start, start + int(match.group(2), 16)))

    functions: dict[int, AlphaFunction] = {}
    for line in lines:
        match = MAP_SYMBOL_RE.match(line)
        if not match:
            continue

        address = int(match.group(1), 16)
        size = int(match.group(2), 16)
        if address == 0 or size == 0:
            continue
        if not any(start <= address < end for start, end in text_ranges):
            continue

        functions.setdefault(address, AlphaFunction(address, size, match.group(3)))

    return sorted(functions.values(), key=lambda function: function.address)


def load_anchors(symbol_port_path: Path) -> list[Anchor]:
    anchors_by_alpha: dict[int, Anchor] = {}
    with symbol_port_path.open(newline="", encoding="utf-8-sig") as source:
        for row in csv.DictReader(source):
            alpha_address = parse_int(row["alpha_addr"])
            anchor = Anchor(alpha_address, parse_int(row["retail_addr"]))
            previous = anchors_by_alpha.get(alpha_address)
            if previous and previous != anchor:
                raise ValueError(
                    f"conflicting retail anchors for alpha 0x{alpha_address:08X}: "
                    f"0x{previous.retail_address:08X} and 0x{anchor.retail_address:08X}"
                )
            anchors_by_alpha[alpha_address] = anchor

    return sorted(anchors_by_alpha.values(), key=lambda anchor: anchor.alpha_address)


def load_known_ghidra_starts(ghidra_csv_path: Path) -> set[int]:
    starts: set[int] = set()
    with ghidra_csv_path.open(newline="", encoding="utf-8-sig") as source:
        for row in csv.DictReader(source):
            starts.add(parse_int(row["Start"]))
    return starts


def load_text_ranges(elf_path: Path) -> list[AddressRange]:
    data = elf_path.read_bytes()
    if data[:4] != b"\x7fELF" or data[4] != 1 or data[5] != 1:
        raise ValueError(f"expected a little-endian ELF32 file: {elf_path}")

    section_offset = struct.unpack_from("<I", data, 0x20)[0]
    section_entry_size, section_count, string_index = struct.unpack_from("<HHH", data, 0x2E)
    if section_entry_size < 40 or section_count == 0 or string_index >= section_count:
        raise ValueError(f"ELF has no usable section table: {elf_path}")

    def section_header(index: int) -> tuple[int, ...]:
        return struct.unpack_from("<IIIIIIIIII", data, section_offset + index * section_entry_size)

    string_header = section_header(string_index)
    string_data = data[string_header[4] : string_header[4] + string_header[5]]

    def section_name(offset: int) -> str:
        end = string_data.find(b"\0", offset)
        if end < 0:
            end = len(string_data)
        return string_data[offset:end].decode("ascii", errors="replace")

    ranges: list[AddressRange] = []
    for index in range(section_count):
        header = section_header(index)
        name = section_name(header[0])
        flags, address, size = header[2], header[3], header[5]
        if size and name.startswith(".text") and (flags & 0x4):
            ranges.append(AddressRange(address, address + size, name))

    if not ranges:
        raise ValueError(f"ELF has no executable .text section: {elf_path}")
    return sorted(ranges, key=lambda item: item.start)


def load_generated_owners(generated_dir: Path) -> list[AddressRange]:
    owners: dict[tuple[int, int], AddressRange] = {}
    for source_path in generated_dir.glob("*.cpp"):
        with source_path.open("r", encoding="utf-8", errors="replace") as source:
            header = source.read(1024)
        range_match = OWNER_RANGE_RE.search(header)
        if not range_match:
            continue
        function_match = OWNER_FUNCTION_RE.search(header)
        name = function_match.group(1) if function_match else source_path.stem
        if name.startswith("entry_"):
            continue
        start = int(range_match.group(1), 16)
        end = int(range_match.group(2), 16)
        if end > start:
            owners[(start, end)] = AddressRange(start, end, name)

    if not owners:
        raise ValueError(f"no generated owner ranges found under {generated_dir}")
    return sorted(owners.values(), key=lambda owner: (owner.start, owner.end))


def find_containing_range(
    address: int,
    end_address: int,
    ranges: list[AddressRange],
    starts: list[int],
    *,
    require_split: bool,
) -> AddressRange | None:
    index = bisect.bisect_right(starts, address) - 1
    best: AddressRange | None = None
    while index >= 0 and ranges[index].start <= address:
        candidate = ranges[index]
        if candidate.end > address and candidate.end >= end_address:
            if not require_split or candidate.start < address:
                if best is None or candidate.start > best.start:
                    best = candidate
        if best is not None and candidate.start < best.start:
            break
        index -= 1
    return best


def discover_candidates(
    functions: list[AlphaFunction],
    anchors: list[Anchor],
    known_starts: set[int],
    max_anchor_span: int,
) -> tuple[list[Candidate], list[tuple[AlphaFunction, str]]]:
    anchor_addresses = [anchor.alpha_address for anchor in anchors]
    candidates: list[Candidate] = []
    rejected: list[tuple[AlphaFunction, str]] = []

    for function in functions:
        index = bisect.bisect_left(anchor_addresses, function.address)
        if index == 0 or index == len(anchors):
            continue

        anchor_lo = anchors[index - 1]
        anchor_hi = anchors[index]
        if anchor_lo.delta != anchor_hi.delta:
            continue
        if anchor_hi.alpha_address - anchor_lo.alpha_address >= max_anchor_span:
            continue

        retail_address = function.address + anchor_lo.delta
        if retail_address in known_starts:
            continue

        candidate = Candidate(
            alpha=function,
            retail_address=retail_address,
            delta=anchor_lo.delta,
            anchor_lo=anchor_lo,
            anchor_hi=anchor_hi,
        )
        candidates.append(candidate)

    return candidates, rejected


def validate_candidates(
    candidates: list[Candidate],
    text_ranges: list[AddressRange],
    owners: list[AddressRange],
) -> tuple[list[Candidate], list[tuple[Candidate, str]]]:
    text_starts = [item.start for item in text_ranges]
    owner_starts = [item.start for item in owners]
    accepted: list[Candidate] = []
    rejected: list[tuple[Candidate, str]] = []

    for candidate in candidates:
        address = candidate.retail_address
        size = candidate.alpha.size
        end_address = address + size

        if address & 3:
            rejected.append((candidate, "retail address is not aligned to 4"))
            continue
        if end_address <= address or end_address > 0x1_0000_0000:
            rejected.append((candidate, "ported size overflows the retail address space"))
            continue

        text_range = find_containing_range(
            address, end_address, text_ranges, text_starts, require_split=False
        )
        if text_range is None:
            rejected.append((candidate, "address or size is outside executable .text"))
            continue

        owner = find_containing_range(
            address, end_address, owners, owner_starts, require_split=True
        )
        if owner is None:
            rejected.append((candidate, "not a size-safe split inside an existing owner"))
            continue

        accepted.append(
            Candidate(
                alpha=candidate.alpha,
                retail_address=candidate.retail_address,
                delta=candidate.delta,
                anchor_lo=candidate.anchor_lo,
                anchor_hi=candidate.anchor_hi,
                owner=owner,
            )
        )

    return accepted, rejected


def write_outputs(
    output_path: Path,
    rejected_path: Path,
    accepted: list[Candidate],
    rejected: list[tuple[Candidate, str]],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as target:
        writer = csv.writer(target)
        writer.writerow(
            ["retail_addr", "size", "alpha_name", "delta", "anchor_lo", "anchor_hi"]
        )
        for candidate in sorted(accepted, key=lambda item: item.retail_address):
            writer.writerow(
                [
                    f"0x{candidate.retail_address:08X}",
                    candidate.alpha.size,
                    candidate.alpha.name,
                    f"0x{candidate.delta:X}",
                    f"0x{candidate.anchor_lo.retail_address:08X}",
                    f"0x{candidate.anchor_hi.retail_address:08X}",
                ]
            )

    with rejected_path.open("w", newline="", encoding="utf-8") as target:
        writer = csv.writer(target)
        writer.writerow(
            [
                "alpha_addr",
                "retail_addr",
                "size",
                "alpha_name",
                "delta",
                "anchor_lo",
                "anchor_hi",
                "reason",
            ]
        )
        for candidate, reason in sorted(rejected, key=lambda item: item[0].retail_address):
            writer.writerow(
                [
                    f"0x{candidate.alpha.address:08X}",
                    f"0x{candidate.retail_address:08X}",
                    candidate.alpha.size,
                    candidate.alpha.name,
                    f"0x{candidate.delta:X}",
                    f"0x{candidate.anchor_lo.retail_address:08X}",
                    f"0x{candidate.anchor_hi.retail_address:08X}",
                    reason,
                ]
            )


def build_argument_parser(root: Path) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=root)
    parser.add_argument(
        "--map",
        type=Path,
        default=root / "MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404" / "MC.MAP",
    )
    parser.add_argument(
        "--symbol-port",
        type=Path,
        default=root / "work" / "exports" / "retail_symbol_port.csv",
    )
    parser.add_argument(
        "--ghidra-csv",
        type=Path,
        default=root / "work" / "exports" / "SLUS_213.55.ghidra.csv",
    )
    parser.add_argument(
        "--retail-elf", type=Path, default=root / "extracted_iso" / "SLUS_213.55"
    )
    parser.add_argument(
        "--generated-dir",
        type=Path,
        default=root / "work" / "generated" / "ghidra",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=root / "work" / "exports" / "boundary_port.csv",
    )
    parser.add_argument(
        "--rejected-output",
        type=Path,
        default=root / "work" / "exports" / "boundary_port_rejected.csv",
    )
    parser.add_argument("--max-anchor-span", type=parse_int, default=0x2000)
    parser.add_argument("--expect-count", type=int, default=595)
    return parser


def main(argv: list[str] | None = None) -> int:
    root = Path(__file__).resolve().parent.parent
    args = build_argument_parser(root).parse_args(argv)

    functions = load_alpha_functions(args.map)
    anchors = load_anchors(args.symbol_port)
    known_starts = load_known_ghidra_starts(args.ghidra_csv)
    text_ranges = load_text_ranges(args.retail_elf)
    owners = load_generated_owners(args.generated_dir)

    discovered, _ = discover_candidates(
        functions, anchors, known_starts, args.max_anchor_span
    )
    accepted, rejected = validate_candidates(discovered, text_ranges, owners)
    write_outputs(args.output, args.rejected_output, accepted, rejected)

    print(f"alpha_text_functions={len(functions)}")
    print(f"matched_anchors={len(anchors)}")
    print(f"ghidra_known_starts={len(known_starts)}")
    print(f"same_delta_missing_starts={len(discovered)}")
    print(f"accepted_boundaries={len(accepted)}")
    print(f"rejected_boundaries={len(rejected)}")
    print(f"output={args.output}")
    print(f"rejected_output={args.rejected_output}")

    zip_addresses = {0x4F9910, 0x4F9918, 0x4F9948, 0x4F9950, 0x4F9A48}
    emitted_zip = {candidate.retail_address for candidate in accepted} & zip_addresses
    print("zip_5=" + ",".join(f"0x{address:08X}" for address in sorted(emitted_zip)))

    if args.expect_count >= 0 and len(discovered) != args.expect_count:
        print(
            f"SANITY_ERROR: expected {args.expect_count} same-delta missing starts, "
            f"got {len(discovered)}",
            file=sys.stderr,
        )
        return 2
    if emitted_zip != zip_addresses:
        missing = zip_addresses - emitted_zip
        print(
            "SANITY_ERROR: missing zip boundaries "
            + ",".join(f"0x{address:08X}" for address in sorted(missing)),
            file=sys.stderr,
        )
        return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
