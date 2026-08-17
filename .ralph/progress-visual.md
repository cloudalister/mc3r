## [2026-08-08 23:42 BRT] - VIS-A1: Prove the dominant nondeterminism source
Thread: 
Run: 20260808-234217-310 (iteration 1)
Run log: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260808-234217-310-iter-1.log
Run summary: E:/Emuladores/Sony/mc3recomp/.ralph/runs/run-20260808-234217-310-iter-1.md
- Guardrails reviewed: yes
- No-commit run: true
- Commit: none (No-commit=true; checkout also has no usable Git worktree)
- Post-commit status: not applicable; allowed files changed: docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md, .ralph/progress-visual.md, .ralph/activity.log
- Verification:
  - Command: read-only PowerShell extraction of 2026-08-07 baseline and five raw logs -> PASS
  - Command: read-only source inspection of Thread.cpp, ps2_runtime.cpp, ps2_memory.cpp, Boot-Probe.ps1, Probe-Repeat.ps1 and 14_run_boot_trace.bat -> PASS
  - Command: git status --short -> FAIL (checkout not recognized as a Git repository; no mutation attempted)
- Files changed:
  - docs/PROBE_NONDETERMINISM_ROOT_CAUSE.md
  - .ralph/progress-visual.md
  - .ralph/activity.log
- What was implemented
  - Read-only root-cause report ranking host threads and wall-clock cutoff as proven dominant sources, preserving uninitialized state and RTC as unproven hypotheses.
  - One opt-in A2 budget gate specification with N=10 honest acceptance and rollback.
- **Learnings for future iterations:**
  - `Stable PC` is the final matching telemetry frame, not a terminal guest-state proof.
  - Existing `MC3_DISPATCH_BUDGET` is dormant unless explicitly passed through the probe; the wall-clock driver otherwise force-kills it.
  - `gif>0` or `gsw>0` remains the only visual signal; there is no frame yet.
---
