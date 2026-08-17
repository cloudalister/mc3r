# MC3 Boot Probe Comparison

Updated: 2026-07-08 00:13:09
Seconds per run: 5

| Experiment | Classification | Stable PC | Function | Render counters | Trace |
|---|---|---|---|---|---|
| baseline | sif-reg-poll | 0x246740 | FUN_002466e0_0x2466e0 | dma=0 gif=0 gsw=0 vif=0 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_baseline_20260708_001220.log |
| latch | semaphore | 0x246a80 | FUN_00246880_0x246880 | dma=0 gif=0 gsw=0 vif=0 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_latch_20260708_001225.log |
| stage2 | semaphore | 0x246a80 | FUN_00246880_0x246880 | dma=0 gif=0 gsw=0 vif=0 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_stage2_20260708_001231.log |
| latch-iopqueue | render-started | 0x528fa0 | FUN_00528ca0_0x528ca0 | dma=0 gif=0 gsw=0 vif=2 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_latch-iopqueue_20260708_001236.log |
| latch-iopqueue-gsfield | render-started | 0x540354 | FUN_005402e8_0x5402e8 | dma=0 gif=0 gsw=0 vif=2 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_latch-iopqueue-gsfield_20260708_001242.log |
| latch-iopqueue-gsfield-callback | render-started | 0x245718 | sub_00245680_0x245680 | dma=2 gif=0 gsw=0 vif=3 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_latch-iopqueue-gsfield-callback_20260708_001247.log |
| payload592 | render-started | 0x542318 | FUN_005422c8_0x5422c8 | dma=2 gif=0 gsw=0 vif=3 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_payload592_20260708_001253.log |
| pollsid | render-started | 0x245720 | sub_00245680_0x245680 | dma=2 gif=0 gsw=0 vif=3 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_pollsid_20260708_001258.log |
| pollsid59c | render-started | 0x1a0e84 | sub_001A0DB0_0x1a0db0 | dma=0 gif=0 gsw=0 vif=6 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_pollsid59c_20260708_001304.log |
| pollsid59c595 | semaphore | 0x39923c | sub_003991F0_0x3991f0 | dma=0 gif=0 gsw=0 vif=0 | D:\TARS\Emuladores\Sony\Playstation 2\isos\mc3recomp\work\boot_probe\boot_trace_pollsid59c595_20260708_001309.log |

## Decision

At least one experiment moved the stable PC or started render traffic. Inspect that trace as the next blocker.
