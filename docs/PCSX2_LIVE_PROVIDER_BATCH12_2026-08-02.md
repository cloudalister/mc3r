# PCSX2 live provider batch 12

Timestamp: `2026-08-02 05:17 BRT` (`America/Sao_Paulo`)

## Asset container correction

The extracted ISO was verified directly:

```text
ASSETS.DAT   1,444,214,784 bytes  header Dave
STREAMS.DAT  1,025,642,496 bytes  header Hash
TEXTURE.DAT    794,839,040 bytes  header Dave
BANKS.DAT       52,967,424 bytes  header DAVE
```

No loose `.strtbl`/`.pal` files or `texture.zip` were found. The live path
`fonts/mcloadstrings.strtbl` must therefore be resolved inside one of these
proprietary containers.

## Context correction

Static review of `0x003B16E8` shows that `0x0085C760` is not the compressed
payload and not a struct with fixed fields. It is a numeric lookup value used
to find a node in global interval lists:

```text
3B16E8
  -> 3AFAE8(context)
  -> 3B03D0(result, context, 1)
  -> 3B1020(result-list + 0xF0, context, result)
```

`3AFAE8` returns the matching node or zero. The meaningful live follow-up is
to observe the node pointer and writes in `3B03D0/3B1020`, not to decode
`0x0085C760` as asset bytes. The previous raw `v0=0x118EDCC3` is therefore
not promoted as a handle or success value.

## Next live targets

Arm breakpoints at:

```text
0x003AFAE8  interval-node lookup
0x003B03D0  node/result processing
0x003B1020  list update and node writes
```

Then correlate the selected node with the stream record
`0x0078C5FF / 0x0003CB70 / 0x0000D967`. No runtime patch or container rewrite
is authorized by this evidence yet.
