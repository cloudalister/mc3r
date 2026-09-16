# mc3r

Static recompilation of *Midnight Club 3: DUB Edition Remix* (PS2, region
`SLUS_213.55`) into a native PC build, using a fork of
[PS2Recomp](https://github.com/cloudalister/PS2Recomp).

This repository contains **only tooling and generated-code infrastructure**.
It does not, and will never, contain the game's ISO, extracted filesystem,
ELF, or any asset/audio/texture data. To build anything you need your own
legally obtained copy of the game — see "Requirements" below.

**[See the visual progress map →](docs/EXPLICA_VISUAL.html)** — a one-page,
illustrated walkthrough of where the recompilation currently stands (boot,
menu blocker, rendering bug), updated 2026-09-16. This file isn't rendered
by GitHub's own file viewer; open it locally after cloning, or enable
GitHub Pages for this repo to get it a public URL (see the note at the
bottom of this file).

## Current state (honest, as of 2026-09-15)

Source of truth is [`STATUS.md`](STATUS.md) (Portuguese, overwritten on every
session). Summary in English:

- The PS2 boot sequence is deterministic and the game reaches the title
  screen / "PRESS START" prompt.
- Pressing start advances the internal menu state (gate flags open,
  293/293-ish opcode-level tests passing against the ELF at time of writing),
  but the **menu screen after START never receives its list of items** — see
  `docs/RESULT_MENU_ITEMS_2026-09-15.md`. This is proven by direct
  instrumentation, not guessed: the menu panel object's child pointer
  (offset `+0x74`) is never written, and its renderer is a no-op (`jr
  ra;nop`) matching the original ELF exactly. The write site that should
  populate this pointer has not yet been found in the ELF.
- Live rendering works, but is visually broken: the panel behind the title
  is cut diagonally (only half of a quad renders) — root cause not yet
  proven, see `docs/RESULT_RENDER_FPS_2026-09-15.md`.
- Frame rate measured live at **~44.7 Hz** against a 60 Hz target. Of the
  three instrumented render subsystems, the **VIF1 interpreter** is the
  single largest measured cost (137.1s cumulative in one 460s sample),
  ahead of VU1 emulation (87.8s) and the software GS rasterizer (61.0s).
- No optimization has been applied yet for either the FPS or the rendering
  bug; both are open investigations. Do not read "measured" numbers above as
  fixed — they are one sampled run, documented with method and caveats in
  the linked docs.

Nothing here should be read as "the game plays." It boots deterministically
and reaches a stuck, partially-rendered menu.

## Repository layout

- `STATUS.md` — start here. One page, always current.
- `docs/CAMINHO_ATE_O_FRAME.md` — milestone ladder (M0-M6) toward a first
  correct frame, and why it isn't there yet.
- `docs/RESULT_*.md` / `docs/HANDOFF_*.md` — dated investigation logs (mixed
  Portuguese/English), append-only history of what was tried and measured.
- `PS2_PROJECT_STATE.md` — long-running changelog (append-only).
- `PS2Recomp/` — git submodule, the recompiler/runtime fork.
- `NN_*.bat` + `tools/` — the pipeline: ISO extraction → Ghidra export →
  recompilation → compile → link → boot probe.
- `.agents/`, `.codex/`, `.ralph/` — automation/agent harnesses used to run
  long unattended investigation sessions. Not required to build the project
  by hand.

## Requirements

- Your own copy of *Midnight Club 3: DUB Edition Remix* (PS2), ISO or disc
  image, region `SLUS_213.55`. **Not provided, not linked, not accepted in
  issues or PRs.**
- Windows (the pipeline scripts are `.bat`/PowerShell; portions of the
  runtime are cross-platform C++ but the tooling has only been exercised on
  Windows so far).
- Ghidra (for the export step), CMake + a C++ toolchain (for building
  `PS2Recomp` and the recompiled runtime).
- PCSX2 is useful as a reference emulator for comparison, but is not a
  dependency of the build itself.

## Building (outline)

1. Place your own ISO in the repository root (never committed — see
   `.gitignore`).
2. Run the numbered `.bat` scripts in order starting from
   `01_extract_iso.bat`; each does one pipeline stage (extraction → Ghidra
   export → recompilation → compilation → linking → boot probe). See
   `docs/PIPELINE.md` for the full description of each stage.
3. Generated code and build output land under `work/` (git-ignored, and
   regenerated from your own ISO — never distributed).

This is a research/reverse-engineering pipeline, not a one-command build;
expect to read `STATUS.md` and the relevant `docs/HANDOFF_*` file before a
session to understand what the last person left off with.

## What this project does not provide

- No game files of any kind (ISO, extracted filesystem, ELF, textures,
  audio, save states).
- No compiled binary of the recompiled game.
- No guarantee of a playable build — see "Current state" above.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md). Open issues are tracked in
`docs/ISSUES_PROPOSED.md` pending upload to GitHub.

## License

Licensing for the tooling/runtime code in this repository (explicitly
**not** for any game asset, which this repo never contains) has not been
finalized — see the note in `LICENSE`. This is a decision for the repository
owner, not assumed here.

## Publishing the visual map with a public URL

`docs/EXPLICA_VISUAL.html` renders fine opened locally, but to give it a
shareable link: repo Settings → Pages → Source: "Deploy from a branch" →
Branch `main`, folder `/docs` → Save. GitHub then serves this file at
`https://<owner>.github.io/mc3r/EXPLICA_VISUAL.html`. This has not been
enabled — it's a one-click setting for the repository owner to turn on.
