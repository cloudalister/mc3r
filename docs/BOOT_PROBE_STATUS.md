# MC3 Boot Probe Status

Updated: 2026-08-19 00:16:12
Mode: probe
Seconds: 15
Trace log: E:\Games\Emuladores\Sony\mc3recomp\work\logs\14_run_boot_trace.log
Driver log: E:\Games\Emuladores\Sony\mc3recomp\work\logs\15_auto_boot_probe_20260819_001556.log
Partial runner timestamp: 2026-08-19 00:14:38

## Summary

| Field | Value |
|---|---|
| Classification | unknown-loop |
| Detail | no known blocker pattern matched |
| Stable PC | 0x1a0138 |
| RA | 0x0 |
| SP | 0x0 |
| GP | 0x0 |
| Function | entry_0x1a0008 |
| File | E:\Games\Emuladores\Sony\mc3recomp\work\generated\ghidra\entry_0x1a0008.cpp |
| Resolve evidence | register_functions.cpp |
| Render counters | dma=0 gif=0 gsw=0 vif=0 gifPk1=0 gifPk2=0 gifPk3=0 gifPkTotal=0 gsPrims=0 gsPixels=0 |
| Deterministic | yes |
| Dispatch budget | 25000 |
| Dispatch budget marker | no |
| Timeout reached | yes |

## Last Stable Frame

~~~text
[boot-trace:frame] tick=660 activeThreads=1 pc=0x1a0138 ra=0x0 sp=0x0 gp=0x0 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=0 vif=0 gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0
~~~

## Last WaitSema Block

~~~text
n/a
~~~

## Last SIF Reg Reads/Writes

~~~text
n/a
~~~

## Last SIF Command Envelopes

~~~text
n/a
~~~

## Next Action

Inspect the final stable PC and nearby trace window before adding a runtime experiment.
