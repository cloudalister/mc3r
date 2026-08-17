# PCSX2 live provider batch 14

Timestamp: `2026-08-02 05:33 BRT` (`America/Sao_Paulo`)

## Node-list write audit

The live chain reached the processing return at `0x003B0428`. The four
candidate list-write instructions were armed, but none was hit in this
instance. The list remained:

```text
0x00677830:
0x008226C0, 0x0F000008
0x0079A550, 0x1680000C
0x00823610, 0x1E000010
0x0085B140, 0x3C000020
0x00806230, 0x5A000030
0x007D4C10, 0x78000040
0x0062E448, 0x00000000
```

Static mapping explains the armed writes:

```text
3B10CC: node_current + 0x00 = old list head
3B10D0: list head + 0x00 = node_current
3B10D8: previous link + 0x00 = node_current->next
3B10F8: previous link + 0x00 = recursive processing result
```

These are linked-list/cache promotion writes. They do not represent the
compressed asset payload or a provider initialization write.

## Conclusion

The selected node was `0x00677740`, found for lookup value `0x008AD110`, but
this invocation returned through `0x003B0428` without list mutation. The
provider/asset investigation should remain focused on the `.DAT` container
entry and the stream callback; the interval-list path is now classified as
generic cache bookkeeping.

PCSX2 remains paused. No MCP memory, register, provider pointer, handle,
semaphore, or runtime code write was made. Ralph's no-commit check reported no
remaining stories.

## Next target

Capture the caller-side comparison after `0x003B0428` and correlate the
stream's proprietary-container entry. Do not promote the cache-list path to a
render or decompression fix.
