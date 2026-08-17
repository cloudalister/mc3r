# PCSX2 live provider — batch 17 — 2026-08-02

Timestamp: 2026-08-02 05:46:49 -03:00

## Resultado

The callback path from `0x004FCA50` was captured live with no memory or
register writes.

At `0x004FCA70`, the active slot was `0x006F3B10`:

```text
slot+0x08 = 0x0000D967
slot+0x10 = 0x017244B0
slot+0x18 = 0x0003CB70
slot+0x28 = 0x004FBB28
slot+0x2C = 0x004FBB60
```

The next callback breakpoint stopped at `0x004FBB60` with:

```text
a0 = 0x00000000
a1 = 0x01620620
ra = 0x004FCA80
s0 = 0x006F3B10
```

Its live code is a node/table lookup wrapper: it moves `a1` to `a0`, then
calls `0x003B16E8` when the context is nonzero. The context at `0x01620620`
contains readable string-table records, including `smallspace` and Japanese
text. This confirms that the callback is handling the loaded string-table
context, not a physical ISO offset directly.

After returning, the same slot reached the primary callback setup at
`0x004FCA80`:

```text
a0 = 0x00000003
a1 = 0x01620610
a2 = 0x00000010
a3 = 0x00677740
```

Static disassembly confirms the next indirect call uses `slot+0x28` and the
following call uses `slot+0x2C`:

```text
0x004FCA80: lw    a0, 0x30(s0)
0x004FCA84: lw    v0, 0x2C(s0)
0x004FCA88: jalr  v0
0x004FCA8C: lw    a1, 0x28(s1)
0x004FCA90: lw    a0, 0x30(s0)
0x004FCA94: lw    v0, 0x2C(s0)
0x004FCA98: jalr  v0
0x004FCA9C: dmove a1, s1
```

## Conclusão

The live chain now proves the handoff from the stream slot into the string
table node/context. The remaining gap is the physical `.DAT` index mapping:
`0x0000D967`, `0x0003CB70`, and `0x017244B0` are runtime record fields, not
yet proven byte offsets in `STREAMS.DAT`.

PCSX2 was left paused. No ISO, emulator, runtime-code, memory, or register
write was made.

## Próximo lote

Capture the primary callback at `0x004FBB28` with the same slot, then compare
its output against the `0x01620610/0x01620620` string-table records. If the
request changes, return to `0x004FAA10` and capture the accepted `Dave`/`Hash`
container header together with the resulting object.
