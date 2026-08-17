# PCSX2 live provider — batch 19 — 2026-08-02

Timestamp: 2026-08-02 06:15:15 -03:00

## Fechamento físico do asset

The five records at `ASSETS.DAT+0x13EB0` are not five different candidates:
they are byte-for-byte copies of the same asset.

```text
record     physical offset
0x13EB0    0x000DB000
0x13EC0    0x0018D000
0x13ED0    0x24B64800
0x13EE0    0x255C4000
0x13EF0    0x4E8C9000
```

Each record is:

```text
FF 41 02 00 | offset | 70 CB 03 00 | 67 D9 00 00
```

Decoded format:

```text
type:               0x000241FF
expanded size:      0x0003CB70
compressed size:    0x0000D967
compression:        raw DEFLATE (-15), no zlib/gzip header
```

Independent local verification of all five blocks produced the same hashes:

```text
compressed SHA-256: cf1f51c184d0b73343887721bf4d1b795c8353af89224d2822439bd036ee229a
expanded SHA-256:   d28c2b777779c844d7bc058bffbcd216b34eb1407c0d9d29346c137433324685
first smallspace:   expanded offset 0x67B4
expanded length:    0x3CB70
```

The expanded data begins with the string-table header and contains the
`smallspace` entries. This is now confirmed as the physical
`fonts/mcloadstrings.strtbl` payload.

## Live filter

The live filter at `0x004FB0D8` observed the network texture queue repeatedly:

```text
texture/network_friendinvitation.pal
texture/network_onlineracing.pal
texture/network_onlineracing.tex
texture/network_remix.pal
texture/network_remix.tex
```

No new successful `mcloadstrings` request appeared in this window. The prior
exact `fonts/mcloadstrings.strtbl` attempt remains classified as provider
failure because its return at `0x004FB0F0` was `v0 = 0`.

This does not weaken the physical result: the raw DEFLATE payload and decoded
string-table content are independently verified from `ASSETS.DAT`.

## Conclusão

The asset side is solved: the live fields `0xD967` and `0x3CB70` point to a
raw-DEFLATE block family in `ASSETS.DAT`, and all five physical copies expand
to the same string table. `0x017244B0` remains a runtime RAM/object value, not
a file offset.

The remaining live-only task is to catch a successful boot/reload request for
the same path and compare its runtime buffer against the verified expanded
hash. No ISO, emulator memory, register, or runtime-code write was made.

PCSX2 is paused at `0x004FB0D8` while the current path filter is armed.

## Próximo lote

Use the verified block as the oracle. Capture only a nonzero
`fonts/mcloadstrings.strtbl` return, then dump `source+0x04` and compare its
decoded bytes to SHA-256 `d28c2b777779c844d7bc058bffbcd216b34eb1407c0d9d29346c137433324685`.

## Encerramento do lote — 2026-08-02 06:17:37 -03:00

The live path filter was allowed to run through the active UI/menu queue. It
observed `tune/ui/en/*` and `texture/network_*` requests, but no new
`fonts/mcloadstrings.strtbl` request. The filter breakpoint was removed after
the queue entered a stable menu loop.

Final state: PCSX2 DebugServer connected and paused at `0x004FB0D8`; only the
parser/status observation breakpoints remain. Ralph reports no remaining
stories. The physical asset investigation is complete; a new live
`mcloadstrings` capture now requires a boot/reload event that was not generated
by the current paused/menu state.
## 2026-08-02 06:36:05 -03:00 - loader runtime checkpoint

- Added `ps2xRuntime/include/mc3_asset_archive.h` and `src/lib/mc3_asset_archive.cpp`.
- The reader indexes the verified table at `0x13EB0` and inflates raw DEFLATE records.
- Added a synthetic MiniTest and linked zlib through CMake.
- CMake configuration succeeds and finds MSYS2 zlib `1.3.2`.
- Build is currently blocked by the local MSYS2 compiler: `g++` returns exit code 1 even for a minimal `int main(){}` and emits no diagnostic. This is a toolchain issue, not a loader assertion.
- Independent Python validation against `extracted_iso/ASSETS.DAT` still passes all five physical copies: expanded size `0x3CB70`, identical SHA-256 `d28c2b777779c844d7bc058bffbcd216b34eb1407c0d9d29346c137433324685`, and `smallspace` at offset `0x67B4`.

Next exact action: repair/replace the MSYS2 C++ compiler environment, rerun `cmake --build PS2Recomp/out/build --target ps2x_tests`, then validate the runtime reader with the real DAT before wiring it into the generated provider.

## 2026-08-02 06:37:30 -03:00 - build recovered

- Root cause found: PowerShell was invoking MSYS2 without `C:\msys64\ucrt64\bin;C:\msys64\usr\bin` in `PATH`.
- With the corrected PATH, `ps2x_tests` built successfully.
- New `MC3AssetArchive` test passed.
- Full suite result: 262 passed, 2 failed. Existing failures: `VU0 macro mappings cover all S1/S2 enums` and `second interlaced sceGsSyncV should report odd field`.
- No runtime provider wiring claimed yet; the next gate is real-DAT C++ validation, then a narrow provider integration.
- Added optional real-DAT MiniTest through `MC3_ASSETS_DAT`.
- Real `extracted_iso/ASSETS.DAT` validation passed: the `0x000241FF` record inflated to `0x3CB70` and contained `smallspace`.
- With that validation enabled, the suite is 264/265; the only remaining failure is the pre-existing `sceGsSyncV` field test.
- Provider wiring review: the native runner currently exposes `FILE*` handles for loose files, while the MC3 provider needs a virtual handle plus name-to-record mapping. No unsafe replacement was made. Ralph reports no remaining implementation stories.
- Next evidence gate: capture the successful `fonts/mcloadstrings.strtbl` provider return and its node/name mapping, then implement virtual `read/lseek/close` only for confirmed records.

## 2026-08-02 06:45:00 -03:00 - virtual handle design checkpoint

- Parallel review confirmed the existing fd system is `unordered_map<int, FILE*>` in `Syscalls/Helpers/State.h`, with `fioOpen/fioRead/fioLseek/fioClose` in `Syscalls/FileIO.cpp`.
- Safe implementation shape: a parallel virtual-fd table; preserve all existing `FILE*` handles and fall back unchanged.
- The provider backend map is documented as open `0x3984C0`, close `0x398610`, read `0x3986D8`, seek `0x398730`, stat `0x398788`.
- Live capture reached the existing request breakpoint at `0x004FB0D8`, but PCSX2 disconnected before a new `mcloadstrings` success could be captured. No emulator memory/register/provider write occurred.
- Next exact sequence after PCSX2 restart: set breakpoint `0x004FB0D8`, filter `$a1` path for `fonts/mcloadstrings.strtbl`, capture the returned handle and provider node, then implement the confirmed virtual-fd adapter.
