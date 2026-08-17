# PS2 Programming Docs Index

Local reference folder:

`PS2-Programming-Docs`

## Most Relevant For This Recomp

- `EE_Core_Instruction_Set_Manual.pdf`: EE/TX79 instruction semantics.
- `EE_Core_Users_Manual.pdf`: EE core behavior, registers, exceptions, memory model.
- `EE_Users_Manual.pdf`: broader Emotion Engine system details.
- `MIPS_Calling_Conventions_Summary.pdf`: ABI/calling convention reference for function naming and arguments.
- `VU_Users_Manual.pdf`: Vector Unit behavior.
- `vu-instruction-manual.pdf`: VU instruction details.
- `Vector Unit Architecture for Emotion Synthesis.pdf`: VU architecture overview.
- `GS_Users_Manual.pdf`: Graphics Synthesizer behavior.
- `GS_Users_Manual_Supplement.pdf`: GS supplemental details.
- `SPU2_Overview_Manual.pdf`: audio hardware overview.
- `padspecs.txt`: low-level controller protocol and commands.
- `PS2Optimisations.pdf`: performance-oriented PS2 programming notes.

## How We Use These

- Treat these as reference material for validating generated code and runtime stubs.
- Do not use them as proof that a game function does a specific thing; function docs still need Ghidra/generated-code/runtime evidence.
- Use the manuals to resolve ambiguous instruction, VU, GS, SPU2, pad, and calling convention questions.

## Current Runtime-Relevant Observations

- Generated VU/SIMD C++ uses host SSE intrinsics such as `_mm_blendv_ps`.
- Host compilation therefore needs SSE4.1 support (`-msse4.1` with MinGW/GCC).
- The runtime has GS, VU1, IOP, audio, pad, syscall, and kernel-stub surfaces that map naturally to these docs.
