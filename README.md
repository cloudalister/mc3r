# mc3r

Static recompilation of *Midnight Club 3: DUB Edition Remix* (PS2, region
`SLUS_213.55`) into a native PC executable, built on a fork of
[PS2Recomp](https://github.com/cloudalister/PS2Recomp).

This repository contains **tooling only**. It does not, and will never,
contain the game's ISO, extracted filesystem, ELF, or any asset, audio or
texture data, nor any code generated from them. Building requires your own
legally obtained copy of the game.

## Current state

The build boots natively, with no emulator, and reaches the title screen
(last updated 2026-09-30):

- **Boot** reaches `PRESS START BUTTON`.
- **Frame rate**: ~44.7 Hz against the PS2's 60 Hz. Exclusive-time profiling
  (one ~400 s run) shows the software GS rasterizer is the largest graphics
  cost (64.5 s own time), ahead of VU1 (26.6 s) and VIF1 (23.0 s). An earlier
  claim that VIF1 was the largest was wrong: the phase timers are nested and
  the VIF1 timer included VU1 and rasterizer time. Inside the rasterizer,
  ~45% of samples are bilinear texture sampling. No optimization applied yet.
- **Menu (main blocker)**: the recomp creates the same 47 script variables as
  the original and builds the menu item list, but only ~11 minutes after
  boot (immediate after START on the PS2). The delay is thread time, not a
  missing function: the main thread spends ~224 s waiting for its turn versus
  ~98 s executing in a 400 s run, and the network worker thread
  (`netManagerThread::MainLoop`) is the largest single thief of turns.
  Menu options are still not visible in captures.
- **Known rendering bug**: the panel behind the title is cut diagonally —
  only half of a quad is drawn. Cause not yet proven.

These are measurements from single runs, with method and caveats recorded in
the issue descriptions. The game does not play yet.

## Repository layout

- `scripts/NN_*.bat` — pipeline steps: ISO extraction, Ghidra export,
  recompilation, compile, link, boot probe.
- `PS2Recomp/` — submodule: the recompiler and the runtime.
- `docs/ISSUES_PROPOSED.md` — the open problems, written up with the
  evidence gathered so far. Good entry points for contributors.

Probe and analysis scripts used during investigation are kept out of the
repository while they still carry machine-specific paths.

## Requirements

- Windows, MSYS2/UCRT64 toolchain (`g++`), CMake.
- Ghidra 11.4+ and a JDK 21 for the analysis/export step.
- Your own copy of the game to extract `SLUS_213.55` from.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Short version: never attach or
commit game-derived data — no ISO, no ELF, no extracted assets, no generated
sources. Share addresses, opcodes and measurements instead.

## License

See [`LICENSE`](LICENSE). The license covers this repository's own tooling
only; it makes no claim over the original game or anything derived from it.
