#!/usr/bin/env bash
# ~/.claude/hooks/session-end.sh
# AUTO-RUNS at the end of every Claude Code session.
# Writes a fallback memory record to Makabi Memory so nothing is lost
# even if the agent forgets to call remember explicitly.
#
# Master Makabi — Mandatory Memory Discipline backstop.
# Open mode (no token) — chosen by Master Makabi 2026-05-06.

set -euo pipefail

MEMORY_ENDPOINT="${MAKABI_MEMORY_ENDPOINT:-https://memory.mtip.ai/mcp/tools/remember}"
HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown-host)"
USER_VAL="${USER:-${USERNAME:-unknown}}"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE_HUMAN="$(date -u +'%Y-%m-%d %H:%M UTC')"

# Detect surface (claude-code vs cowork) — best-effort from env vars
SURFACE="claude-code"
if [[ -n "${COWORK_SESSION:-}" ]] || [[ -n "${ANTHROPIC_COWORK:-}" ]]; then
  SURFACE="cowork"
fi

# Detect author from env or fall back to USER
AUTHOR="${MAKABI_AUTHOR:-$USER_VAL}"
case "$AUTHOR" in
  michael*|mike*|makabi*|master*) AUTHOR="mike" ;;
  loren*) AUTHOR="loren" ;;
  sanjeev*) AUTHOR="sanjeev" ;;
  harish*) AUTHOR="harish" ;;
  aakash*) AUTHOR="aakash" ;;
  shalu*) AUTHOR="shalu" ;;
esac

# Pull last 50 lines of session transcript if Claude wrote one
TRANSCRIPT_SUMMARY=""
if [[ -f "$HOME/.claude/last-session-summary.md" ]]; then
  TRANSCRIPT_SUMMARY="$(tail -n 50 "$HOME/.claude/last-session-summary.md" | sed 's/"/\\"/g' | tr '\n' ' ')"
fi

# Detect git repo + last commit if we're in one
REPO_INFO=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_NAME="$(basename "$(git rev-parse --show-toplevel)")"
  LAST_COMMIT="$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo 'no-commit')"
  CURRENT_BRANCH="$(git branch --show-current 2>/dev/null || echo 'unknown-branch')"
  REPO_INFO="repo=$REPO_NAME branch=$CURRENT_BRANCH last_commit=\"$LAST_COMMIT\""
fi

# Build the JSON payload
TITLE="${HOSTNAME_VAL} — ${SURFACE} session — ${DATE_HUMAN}"
CONTENT="**Auto-saved session record (SessionEnd hook fallback).**

- Machine: ${HOSTNAME_VAL}
- User: ${USER_VAL}
- Surface: ${SURFACE}
- Timestamp: ${TIMESTAMP}
- ${REPO_INFO}

Transcript tail: ${TRANSCRIPT_SUMMARY:-no-transcript-found}

This is a fallback record. If the agent wrote an explicit memory for this session, that one is the authoritative record."

PAYLOAD=$(cat <<EOF
{
  "topic": "session-log",
  "title": "${TITLE}",
  "content": $(printf '%s' "$CONTENT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
  "author": "${AUTHOR}",
  "source": "${HOSTNAME_VAL}",
  "tags": ["auto-saved", "${SURFACE}", "session-end-hook", "${HOSTNAME_VAL}"],
  "org_id": "makabi"
}
EOF
)

# Fire and forget — don't block session shutdown if memory is down
{
  curl -sS --max-time 5 \
    -X POST "$MEMORY_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    > "$HOME/.claude/last-memory-write.log" 2>&1 || \
    echo "[$(date)] Memory write failed (non-blocking)" >> "$HOME/.claude/memory-hook-errors.log"
} &

exit 0
