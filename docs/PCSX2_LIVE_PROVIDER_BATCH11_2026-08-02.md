# PCSX2 live provider batch 11

Timestamp: `2026-08-02 05:16 BRT` (`America/Sao_Paulo`)

## Callback return

The return from the secondary callback path was captured at `0x004FD35C`:

```text
caller path: 0x4FD340 -> slot+0x2C -> 0x3B16E8 -> 0x4FD35C
context:     0x0085C760
v0 raw low dword: 0x118EDCC3
```

The context remained populated with the previously observed state and buffer
fields:

```text
0x0085C760 +0x00 = 0x00000008
0x0085C760 +0x08 = 0x0000000D
0x0085C760 +0x0C = 0x000052FC
0x0085C760 +0x10 = 0x00000609
0x0085C760 +0x14 = 0x00865370
0x0085C760 +0x18 = 0x008665A0
```

This records the exact live return only; `0x118EDCC3` is not promoted to a
handle, pointer, or success code without a caller-side interpretation.

## Ralph check

The local Ralph loop was run again with one no-commit iteration. It reported
`No remaining stories` and made no changes.

## State and next target

PCSX2 remains paused at the callback-return boundary with no MCP guest-memory,
register, provider, handle, or semaphore writes. The next useful capture is
the caller after `0x4FD35C`, especially how it stores/compares `v0`; do not
classify the raw return before that comparison is observed.
