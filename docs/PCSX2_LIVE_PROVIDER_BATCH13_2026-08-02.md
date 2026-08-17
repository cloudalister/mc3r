# PCSX2 live provider batch 13

Timestamp: `2026-08-02 05:19 BRT` (`America/Sao_Paulo`)

## Interval-node capture

The generic callback state path was followed live:

```text
3B16E8
  -> 3AFAE8(lookup value 0x008AD110)
  -> returns node 0x00677740
  -> 3B03D0(node, 0x008AD110, 1)
  -> 3B1020(node-list, 0x008AD110, node)
```

At `0x003B03D0`:

```text
a0 = 0x00677740   selected node/result
a1 = 0x008AD110   lookup value
a2 = 0x00000001   mode
```

At `0x003B1020`:

```text
a0 = 0x00677830   node-list head from result + 0xF0
a1 = 0x008AD110   lookup value
a2 = 0x00677740   result node
```

The list head contains real interval records, including:

```text
0x008226C0, 0x0F000008
0x0079A550, 0x1680000C
0x00823610, 0x1E000010
0x0085B140, 0x3C000020
0x00806230, 0x5A000030
0x007D4C10, 0x78000040
0x0062E448, 0x00000000
```

This proves the callback context is an interval/node lookup mechanism. It is
not the compressed asset buffer and must not be treated as the `.strtbl`
payload.

## State

PCSX2 is paused at `0x003B1020`. No MCP memory, register, provider pointer,
handle, semaphore, or runtime code write was made.

Ralph was run for one no-commit iteration and again reported no remaining
stories.

## Next target

Capture the node writes after `0x3B1020` and return through `0x3B0428`; keep
the asset investigation separate and use the verified `.DAT` containers for
the eventual `mcloadstrings.strtbl` byte comparison.
