#!/usr/bin/env python3
"""Print module-mapped return-address candidates from a Windows minidump."""

from __future__ import annotations

import logging
import struct
import sys

from minidump.minidumpfile import MinidumpFile


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <dump.dmp>", file=sys.stderr)
        return 2

    logging.disable(logging.CRITICAL)
    dump = MinidumpFile.parse(sys.argv[1])
    reader = dump.get_reader()
    modules = dump.modules.modules

    for thread in dump.threads.threads:
        context = thread.ContextObject
        print(f"thread 0x{thread.ThreadId:x} rip=0x{context.Rip:x} rsp=0x{context.Rsp:x}")
        stack = reader.read(thread.Stack.StartOfMemoryRange, thread.Stack.DataSize)
        emitted = 0
        seen: set[tuple[str, int]] = set()
        for offset in range(0, len(stack) - 7, 8):
            value = struct.unpack_from("<Q", stack, offset)[0]
            module = next(
                (candidate for candidate in modules
                 if candidate.baseaddress <= value < candidate.baseaddress + candidate.size),
                None,
            )
            if module is None:
                continue
            rva = value - module.baseaddress
            module_name = module.name.rsplit("\\", 1)[-1]
            key = (module_name, rva)
            if key in seen:
                continue
            seen.add(key)
            print(f"  sp+0x{offset:04x} {module_name}+0x{rva:x} absolute=0x{value:x}")
            emitted += 1
            if emitted >= 40:
                break
        print()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
