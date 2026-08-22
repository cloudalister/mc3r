# MC3 Boot Probe Status

Updated: 2026-08-22 04:37:32
Mode: probe
Seconds: 8
Trace log: E:\Games\Emuladores\Sony\mc3recomp\work\logs\14_run_boot_trace.log
Driver log: E:\Games\Emuladores\Sony\mc3recomp\work\logs\15_auto_boot_probe_20260822_043723.log
Partial runner timestamp: 2026-08-22 04:36:21

## Summary

| Field | Value |
|---|---|
| Classification | semaphore |
| Detail | [boot-trace:WaitSema:block] tid=3 sid=5 count=0 waiters=0 pc=0x5469e0 ra=0x398b28 |
| Stable PC | 0x223480 |
| RA | 0x2234a8 |
| SP | 0x19fe20 |
| GP | 0x67f070 |
| Function | sub_002233F0_0x2233f0 |
| File | E:\Games\Emuladores\Sony\mc3recomp\work\generated\ghidra\sub_002233F0_0x2233f0.cpp |
| Resolve evidence | register_functions.cpp |
| Render counters | dma=0 gif=0 gsw=0 vif=0 gifPk1=0 gifPk2=0 gifPk3=0 gifPkTotal=0 gsPrims=0 gsPixels=0 |
| Deterministic | yes |
| Dispatch budget | 100000 |
| Dispatch budget marker | no |
| Timeout reached | yes |

## Last Stable Frame

~~~text
[boot-trace:frame] tick=420 activeThreads=2 pc=0x223480 ra=0x2234a8 sp=0x19fe20 gp=0x67f070 dispfb1=0x1400 display1=0x1bf27f00000000 dma=0 gif=0 gsw=0 vif=0 gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0
~~~

## Last WaitSema Block

~~~text
[boot-trace:WaitSema:block] tid=3 sid=5 count=0 waiters=0 pc=0x5469e0 ra=0x398b28
~~~

## Last SIF Reg Reads/Writes

~~~text
[sceSifGetReg] reg=0x80000000 value=0x0 pc=0x546db0 ra=0x5486f4
[sceSifGetReg] reg=0x4 value=0x20000 pc=0x546db0 ra=0x548748
[sceSifGetReg] reg=0x2 value=0x0 pc=0x546db0 ra=0x54875c
[sceSifSetReg] reg=0x80000000 prev=0x0 value=0x0 pc=0x546da0 ra=0x54876c
[sceSifSetReg] reg=0x80000001 prev=0x0 value=0x6fe6d8 pc=0x546da0 ra=0x54877c
[sceSifGetReg] reg=0x80000002 value=0x0 pc=0x546db0 ra=0x548da0
[sceSifSetReg] reg=0x80000002 prev=0x0 value=0x1 pc=0x546da0 ra=0x54a0ac
~~~

## Last SIF Command Envelopes

~~~text
[boot-trace:sceSifSetDma] idx=0 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x40,0x0,0x80000009,0x0,0x5,0x206fe900,0x2,0x701880,0x80000001,0x0,0x0,0x0,0x0,0x0,0x0,0x0 aux[0..7]=0x206fe900,0x2,0x9,0x0,0x0,0x0,0x0,0x0 pc=0x546d60 ra=0x5489dc
[boot-trace:sif-command-compat] cmd=0x80000009 request=0x80000001 aux=0x701880 callback=0x0 sema=9 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=1 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x840,0x0,0x8000000a,0x0,0x5,0x206fe900,0x3,0x701880,0xff,0x8,0x700dc0,0x8,0x1,0x1,0x0,0x0 aux[0..7]=0x206fe900,0x3,0xc,0x0,0x0,0x0,0x67f070,0x0 pc=0x546d60 ra=0x5489dc
[boot-trace:sif-command-compat] cmd=0x8000000a request=0xff aux=0x701880 callback=0x0 sema=12 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
~~~

## Next Action

Find the producer expected to signal the blocked semaphore before adding compatibility.
