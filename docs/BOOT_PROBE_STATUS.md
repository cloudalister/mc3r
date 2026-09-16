# MC3 Boot Probe Status

Updated: 2026-08-23 04:46:01
Mode: pollsid59c595
Seconds: 8
Trace log: <project-root>\work\logs\14_run_boot_trace.log
Driver log: <project-root>\work\logs\15_auto_boot_probe_20260823_044552.log
Partial runner timestamp: 2026-08-23 04:43:45

## Summary

| Field | Value |
|---|---|
| Classification | counters-moved |
| Detail | dma/vif counters moved without gif/gsw visual traffic |
| Stable PC | 0x4b2374 |
| RA | 0x4b2374 |
| SP | 0x19fb60 |
| GP | 0x67f070 |
| Function | sub_004B2318_0x4b2318 |
| File | <project-root>\work\generated\ghidra\sub_004B2318_0x4b2318.cpp |
| Resolve evidence | register_functions.cpp |
| Render counters | dma=2 gif=0 gsw=0 vif=3 gifPk1=0 gifPk2=0 gifPk3=0 gifPkTotal=0 gsPrims=0 gsPixels=0 |
| Deterministic | no |
| Dispatch budget | n/a |
| Dispatch budget marker | no |
| Timeout reached | yes |

## Last Stable Frame

~~~text
[boot-trace:frame] tick=420 activeThreads=5 pc=0x4b2374 ra=0x4b2374 sp=0x19fb60 gp=0x67f070 dispfb1=0x1400 display1=0x1bf27f00000000 dma=2 gif=0 gsw=0 vif=3 gifPk1=0 gifPk2=0 gifPk3=0 gsPrims=0 gsPixels=0
~~~

## Last WaitSema Block

~~~text
[boot-trace:WaitSema:block] tid=4 sid=73 count=0 waiters=0 pc=0x5469e0 ra=0x1f7150
~~~

## Last SIF Reg Reads/Writes

~~~text
[sceSifSetReg] reg=0x4 prev=0x40000 value=0x10000 pc=0x546da0 ra=0x54bfb4
[sceSifSetReg] reg=0x4 prev=0x10000 value=0x20000 pc=0x546da0 ra=0x54bfc0
[boot-trace:intc-stat-latch] cause=3[sceSifSetReg] reg=0x80000002 prev=0x1 value=0x0 pc=0x546da0 ra=0x54bfd0
[sceSifSetReg] reg=0x80000000 prev=0x0 value=0x0 pc=0x546da0 ra=0x54bfdc
[sceSifGetReg] reg=0x4 value=0x60000 pc=0x546db0 ra=0x54c010
[boot-trace:intc-stat-latch] cause=[sceSifGetReg] reg=0x80000000 value=0x0 pc=0x546db0 ra=0x5486f4
[sceSifGetReg] reg=0x4 value=0x60000 pc=0x546db0 ra=0x548748
[sceSifGetReg] reg=0x2 value=0x0 pc=0x546db0 ra=0x54875c
[sceSifSetReg] reg=0x80000000 prev=0x0 value=0x0 pc=0x546da0 ra=0x54876c
[sceSifSetReg] reg=0x80000001 prev=0x6fe6d8 value=0x6fe6d8 pc=0x546da0 ra=0x54877c
[sceSifGetReg] reg=0x80000002 value=0x0 pc=0x546db0 ra=0x548da0
[sceSifSetReg] reg=0x80000002 prev=0x0 value=0x[boot-trace:intc-stat-latch] cause=3 intcStat=0xc
~~~

## Last SIF Command Envelopes

~~~text
[boot-trace:sif-command-compat] cmd=0x8000000a request=0x1 aux=0x620d50 callback=0x5413f0 sema=4294967295 signaled=1 callbackSignaled=0 callbackHandled=1 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=0 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x40,0x0,0x8000000a,0x0,0x5,0x206fe900,0x49,0x621700,0x4,0x0,0x620d80,0x4,0x1,0x1,0x0,0x0 aux[0..7]=0x206fe900,0x49,0x52,0x0,0x0,0x0,0x67f070,0x0 pc=0x546d60 ra=0x5489dc
[boot-trace:sif-command-compat] cmd=0x8000000a request=0x4 aux=0x621700 callback=0x0 sema=82 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=0 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x40,0x0,0x8000000a,0x0,0x5,0x206fe900,0x4a,0x620d50,0xe,0x0,0x61fc00,0x4,0x1,0x1,0x0,0x0 aux[0..7]=0x206fe900,0x4a,0x53,0x0,0x0,0x0,0x67f070,0x0 pc=0x546d60 ra=0x5489dc
[boot-trace:mc3-iop-response-experiment] kind=request-595-complete request=0xe payload=0x61fc00 size=0x4 value=0x1 requestNode=0x206fe900 queueNode=0x0 queueSeq=0x0 nodeSeq=0x0 queueFlags=0x0 queueCleared=0 queueSeqSynced=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sif-command-compat] cmd=0x8000000a request=0xe aux=0x620d50 callback=0x0 sema=83 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=1 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x1840,0x0,0x8000000a,0x0,0x5,0x206fe900,0x4b,0x620d50,0x1,0x18,0x0,0x0,0x1,0x1,0x0,0x0 aux[0..7]=0x206fe900,0x4b,0xffffffff,0x0,0x0,0x0,[boot-trace:vblank-tick] tick=b0 deterministic=0
[boot-trace:sif-command-compat] cmd=0x8000000a request=0x1 aux=0x620d50 callback=0x5413f0 sema=4294967295 signaled=1 callbackSignaled=0 callbackHandled=1 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=0 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x40,0x0,0x80000009,0x0,0x5,0x206fe900,0x4c,0x6f6700,0x46d046d,0x18,0x0,0x0,[boot-trace:vblank-tick] tick=148 deterministic=0x1,0x1,0x00
[boot-trace:sif-command-compat] cmd=0x80000009 request=0x46d046d aux=0x6f6700 callback=0x0 sema=86 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
[boot-trace:sceSifSetDma] idx=1 src=0x206fe900 dest=0x0 size=0x40 attr=0x44 words=0x24040,0x0,0x8000000a,0x0,0x5,0x206fe900,0x4d,0x6f6700,0xc,0x240,0x6f6740,0x240,0x1,0x1,0x0,0x0 aux[0..7]=0x206fe900,0x4d,0x57,0x0,0x0,0x0,0x67f070,0x0 pc=0x546d60 ra=0x5489dc
[boot-trace:sif-command-compat] cmd=0x8000000a request=0xc aux=0x6f6700 callback=0x0 sema=87 signaled=1 callbackSignaled=0 callbackHandled=0 endCallbackInvoked=0 pc=0x546d60 ra=0x5489dc
~~~

## Next Action

DMA/VIF moved without GIF/GS writes; this is not visual render. Inspect the transport path and blocker evidence.
