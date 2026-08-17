# PCSX2 live provider batch 8

Timestamp: `2026-08-02 04:49 BRT` (`America/Sao_Paulo`)

## Ralph and parallel audit

The local Ralph loop was executed with the existing provider-investigation PRD:

```text
ralph build 1 --no-commit
result: No remaining stories.
```

Ralph made no code change or commit. A parallel read-only audit closed the
finalizer map independently.

## Finalizer map

```text
4FB4B0
 ├─ validates header byte 0x31 and size 0x48
 ├─ calls object +0x28
 ├─ processes result/status
 ├─ calls 4FBDD8
 ├─ on failure calls 4FB3E0
 └─ fallback calls 4FB440
```

Object fields:

```text
+0x24 = result/state object
+0x28 = primary processing callback; fallback 0x4FBB28
+0x2C = secondary callback; fallback 0x4FBB60
+0x30 = opaque callback context
```

Known return/status values:

```text
 0   success/neutral return
-2   missing object or result
-4   secondary finalization failure
-6   invalid input header/size (not 0x31 / 0x48)
 7   internal state marker used by 4FB3E0
 6   special state checked by 4FBDD8
```

## Combined conclusion

The live zlib strings occur inside the provider callback before these
finalization statuses. The provider is present and the package-open result is
nonzero, but the selected binary stream still has not been correlated to the
requested `fonts/texture/minidub_00.pal`. The next useful live capture is the
input object at `0x4FB0D8`, followed by the callback's source pointer/length.

PCSX2 remains paused in the system loop with observation breakpoints armed.
No guest memory, register, provider pointer, handle, or semaphore was changed.
