# PCSX2 live provider batch 6

Timestamp: `2026-08-02 04:41 BRT` (`America/Sao_Paulo`)

## Result

No second package-open event occurred during a 10-second live window. PCSX2
was paused again without MCP writes. The retry breakpoint remains armed at
`0x004FB4B0`.

## Candidate stream object

The slot/object state was read while paused:

```text
slot area: 0x006F3B00
candidate object: 0x007340F0
```

The object contains repeated pointer/size records, including:

```text
0x0078C35F, 0x00100800, 0x0000440E, 0x00000BD4
0x0078C359, 0x00101800, 0x0000204E, 0x00000C0A
0x0078C353, 0x00102800, 0x0000440E, 0x00000DF2
```

The bytes at `0x0078C35F` are nonzero binary data, beginning:

```text
7e18766287a516a528079ab100f9781e68c602f8b81c68c602...
```

This is the first concrete candidate for the package's loaded binary stream
or entry table. It is not yet proven to be the exact `minidub_00.pal` payload;
the pointer/size record must be matched to the package path before any asset
comparison or runtime change.

## Next target

Use the next package-open hit to correlate the path with the object record,
then compare the selected pointer and size against the ISO/package bytes. Do
not assume `0x0078C35F` is the payload solely because it is nonzero.
