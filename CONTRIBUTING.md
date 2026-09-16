# Contributing to mc3r

This is a reverse-engineering / static-recompilation project for *Midnight
Club 3: DUB Edition Remix* (PS2). Please read this before opening an issue
or PR.

## Legal ground rules (non-negotiable)

- **Never attach, link, or paste** the game's ISO, extracted filesystem,
  ELF, textures, audio, save files, or any other asset extracted from the
  game — in an issue, a PR, a commit, or a comment. This includes partial
  dumps ("just the menu textures") and screenshots that expose copyrighted
  in-game art assets used for anything beyond a small bug-report excerpt.
- Do not ask for or share download links to the game.
- Code contributions must describe *behavior* (addresses, opcodes,
  disassembly snippets used for analysis, structure layouts) rather than
  redistribute game data files. Small disassembly excerpts used to document
  a bug (a handful of instructions, as already used throughout `docs/`) are
  the existing project norm and are fine.
- If you are unsure whether something you want to share is a game asset,
  don't post it — ask first.

## Before you start

1. Read `README.md` for the current state.
2. Read `docs/ISSUES_PROPOSED.md` for the open problems and the evidence
   already gathered, so work isn't repeated: the diagonally cut menu quad,
   the ~44.7 Hz frame rate ceiling, and the menu items never populating
   after START.

## What a good contribution looks like

- **Investigation reports**: post findings in the relevant issue
  following the existing format — state clearly what was *measured* vs.
  *hypothesized*, cite file:line references, and say explicitly what wasn't
  done ("no probe was run", "no binary was recompiled") rather than implying
  more than was verified. 
## Style

- Comments and docs may be in Portuguese or English; existing `docs/`
  content is predominantly Portuguese. New files aimed at outside
  contributors (README, CONTRIBUTING, issues) should be in English.
- File paths in anything committed must be generic/relative
  (`<repo>/...`), never a contributor's or maintainer's personal machine
  path.

## Getting help

Open a GitHub issue for questions. There is no other support channel at
this time.
