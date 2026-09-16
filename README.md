# mc3r

Static recompilation of *Midnight Club 3: DUB Edition Remix* (PS2, region
`SLUS_213.55`) into a native PC executable, built on a fork of
[PS2Recomp](https://github.com/cloudalister/PS2Recomp).

This repository contains **tooling only**. It does not, and will never,
contain the game's ISO, extracted filesystem, ELF, or any asset, audio or
texture data, nor any code generated from them. Building requires your own
legally obtained copy of the game.

## Current state

The build boots natively, with no emulator, and reaches the title screen:

- **Boot** is deterministic and reaches `PRESS START BUTTON`.
- **Frame rate**: ~44.7 Hz against the PS2's 60 Hz, measured over a 460 s
  sample. Of the three instrumented subsystems, the VIF1 interpreter is the
  largest single cost (137.1 s cumulative), ahead of VU1 (87.8 s) and the
  software GS rasterizer (61.0 s). No optimization has been applied.
- **Menu (main blocker)**: after START the next panel appears, but without
  its options. Every function on that path is now implemented and verified
  opcode-by-opcode against the original ELF — zero missing lookups in a
  20-minute run. Instrumentation of the running build shows it creates 41 of
  the 47 script variables the original creates; the six missing ones
  (`offSetX`, `offSetY`, `lineheight`, `scrollable`, `currentselection`,
  `actualselection`) are exactly the properties describing the menu's item
  list. They are registered in the original at `0x33F728` and in the body
  entered at `0x340AC8`; neither is reached in this build yet.
- **Known rendering bug**: the panel behind the title is cut diagonally —
  only half of a quad is drawn. Cause not yet proven.

These are measurements from single runs, with method and caveats recorded in
the issue descriptions. The game does not play yet: it boots and stops at a
partially rendered menu.

## Repository layout

- `scripts/NN_*.bat` — pipeline steps: ISO extraction, Ghidra export,
  recompilation, compile, link, boot probe.
- `PS2Recomp/` — submodule: the recompiler and the runtime.
- `docs/ISSUES_PROPOSED.md` — the three open problems, written up with the
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
