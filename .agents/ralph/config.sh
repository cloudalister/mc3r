# Optional Ralph config overrides.
# All paths are relative to repo root unless absolute.
# Uncomment and edit as needed.

PRD_PATH=".agents/tasks/prd-mc3-visual-gate-a2-2026-08-08.json"
# PROGRESS_PATH=".ralph/progress.md"
# GUARDRAILS_PATH=".ralph/guardrails.md"
# ERRORS_LOG_PATH=".ralph/errors.log"
# ACTIVITY_LOG_PATH=".ralph/activity.log"
# TMP_DIR=".ralph/.tmp"
# RUNS_DIR=".ralph/runs"
# GUARDRAILS_REF=".agents/ralph/references/GUARDRAILS.md"
# CONTEXT_REF=".agents/ralph/references/CONTEXT_ENGINEERING.md"
ACTIVITY_CMD=".agents/ralph/log-activity.cmd"
# AGENT_CMD defaults are defined in agents.sh. Override here if needed.
AGENT_CMD="/c/Users/SAS/AppData/Local/Programs/OpenAI/Codex/bin/codex.exe exec --yolo --skip-git-repo-check -m gpt-5.6-terra -c model_reasoning_effort=low -"
# PRD_AGENT_CMD defaults are defined in agents.sh (interactive).
# PRD_AGENT_CMD="codex --yolo --skip-git-repo-check {prompt}"
# AGENT_CMD="claude -p --dangerously-skip-permissions \"\$(cat {prompt})\""
# AGENT_CMD="droid exec --skip-permissions-unsafe -f {prompt}"
# AGENTS_PATH="AGENTS.md"
# PROMPT_BUILD=".agents/ralph/PROMPT_build.md"
# NO_COMMIT=false
# MAX_ITERATIONS=25
# STALE_SECONDS=0
