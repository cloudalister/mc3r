# US-009: Investigate FMV path separately

Work autonomously in `E:/Emuladores/Sony/mc3recomp` on exactly this story.
Read `AGENTS.md`, `.ralph/guardrails.md`, the PRD, `.ralph/progress.md`, and
relevant existing docs first. Allowed paths are only `work/generated/ghidra`
and `docs`. Findings only; no patch to runtime code.

Map callbacks `0x541348` and `0x5413F0` and their package requests. Identify
whether the callback appears before or after the `0x5A8908` loop. Do not add
`MC3_SKIP_VIDEO` or any compatibility bypass without a concrete player/decision
function. Preserve existing evidence and generated source. Document exact
evidence, unknowns, commands and timestamp in a focused report, update the
Ralph progress/activity handoff as appropriate, and verify with static searches
and any safe headless probe needed. Do not claim visual gameplay acceptance
from hashes, counters or logs alone. Do not commit.

At the end, report the files changed and verification results, and emit
`<promise>COMPLETE</promise>` only if the findings report and checks are done.
