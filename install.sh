#!/usr/bin/env bash
# install.sh — Makabi Mandatory Memory Discipline installer
# Master Makabi — open mode, no token, every machine
#
# ONE-LINE INSTALL (per machine):
#   curl -sL https://raw.githubusercontent.com/michaelmakabi/makabi-memory-discipline/main/install.sh | bash
#
# Or if you cloned the repo:
#   bash install.sh
#
# What this does:
#   1. Creates ~/.claude/ if missing
#   2. Installs ~/.claude/CLAUDE.md (global rules)
#   3. Installs ~/.claude/hooks/session-end.sh (auto-write hook)
#   4. Merges ~/.claude/settings.json to register the hook
#   5. Smoke-tests by writing a memory to confirm reachability

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/michaelmakabi/makabi-memory-discipline/main"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
mkdir -p "$HOOKS_DIR"

HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown)"
USER_VAL="${USER:-unknown}"

echo "================================================="
echo "  MAKABI MEMORY DISCIPLINE — INSTALLER"
echo "  Machine: $HOSTNAME_VAL"
echo "  User:    $USER_VAL"
echo "================================================="
echo ""

# Detect if running from cloned repo or from curl
SCRIPT_DIR=""
if [[ -f "$(dirname "$0")/CLAUDE.md" ]] 2>/dev/null; then
  SCRIPT_DIR="$(dirname "$0")"
  echo "→ Running from cloned repo at $SCRIPT_DIR"
else
  echo "→ Running via curl — fetching files from GitHub"
fi

fetch_file() {
  local filename="$1"
  local dest="$2"
  if [[ -n "$SCRIPT_DIR" ]] && [[ -f "$SCRIPT_DIR/$filename" ]]; then
    cp "$SCRIPT_DIR/$filename" "$dest"
  else
    curl -fsSL "$REPO_BASE/$filename" -o "$dest"
  fi
}

# ---- 1. CLAUDE.md ----
if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
  BACKUP="$CLAUDE_DIR/CLAUDE.md.bak.$(date +%s)"
  echo "→ Backing up existing CLAUDE.md to $BACKUP"
  cp "$CLAUDE_DIR/CLAUDE.md" "$BACKUP"
fi
fetch_file "CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "✓ Installed $CLAUDE_DIR/CLAUDE.md"

# ---- 2. session-end.sh hook ----
fetch_file "session-end.sh" "$HOOKS_DIR/session-end.sh"
chmod +x "$HOOKS_DIR/session-end.sh"
echo "✓ Installed $HOOKS_DIR/session-end.sh (executable)"

# ---- 3. Merge settings.json ----
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [[ -f "$SETTINGS_FILE" ]]; then
  echo "→ Existing settings.json found — merging hook entry"
  cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak.$(date +%s)"
  python3 - "$SETTINGS_FILE" <<'EOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
existing = json.loads(settings_path.read_text())

new_hook = {
    "matcher": "*",
    "hooks": [{"type": "command", "command": "$HOME/.claude/hooks/session-end.sh"}]
}

existing.setdefault("hooks", {})
existing["hooks"].setdefault("SessionEnd", [])

already = any(
    any(h.get("command","").endswith("session-end.sh") for h in entry.get("hooks", []))
    for entry in existing["hooks"]["SessionEnd"]
)
if not already:
    existing["hooks"]["SessionEnd"].append(new_hook)

settings_path.write_text(json.dumps(existing, indent=2))
print("✓ Merged hook into existing settings.json")
EOF
else
  fetch_file "settings.json" "$SETTINGS_FILE"
  echo "✓ Installed fresh $SETTINGS_FILE"
fi

# ---- 4. Smoke test ----
echo ""
echo "→ Smoke-testing memory write to https://memory.mtip.ai..."
TEST_PAYLOAD=$(cat <<EOF
{
  "topic": "session-log",
  "title": "$HOSTNAME_VAL — memory-discipline installer ran — $(date -u +'%Y-%m-%d %H:%M UTC')",
  "content": "Memory discipline installer completed on $HOSTNAME_VAL by user $USER_VAL. CLAUDE.md, SessionEnd hook, and settings.json all in place. This is the bootstrap memory record for this machine.",
  "author": "mike",
  "source": "$HOSTNAME_VAL",
  "tags": ["auto-saved", "installer", "memory-discipline-bootstrap", "$HOSTNAME_VAL"],
  "org_id": "makabi"
}
EOF
)

HTTP_CODE=$(curl -sS --max-time 10 \
    -o /tmp/memory-smoke-test.log \
    -w "%{http_code}" \
    -X POST "https://memory.mtip.ai/mcp/tools/remember" \
    -H "Content-Type: application/json" \
    -d "$TEST_PAYLOAD" || echo "000")

if [[ "$HTTP_CODE" =~ ^2 ]]; then
  echo "✓ Memory smoke test succeeded (HTTP $HTTP_CODE)"
else
  echo "✗ Memory smoke test returned HTTP $HTTP_CODE"
  echo "  See /tmp/memory-smoke-test.log for details"
  echo "  Installer files are in place — hook will retry on session end"
fi

echo ""
echo "================================================="
echo "  INSTALLATION COMPLETE"
echo "================================================="
echo ""
echo "Files installed:"
echo "  • $CLAUDE_DIR/CLAUDE.md"
echo "  • $HOOKS_DIR/session-end.sh"
echo "  • $SETTINGS_FILE"
echo ""
echo "Manual steps remaining (one-time, per device):"
echo "  • Cowork:    Paste cowork-instructions-append.md into your"
echo "               Cowork Instructions field"
echo "  • Claude.ai: Paste user-preferences-append.md into Settings →"
echo "               Profile → User Preferences"
echo ""
echo "Verify:"
echo "  Open Claude Code in any folder, end the session, then:"
echo "    cat ~/.claude/last-memory-write.log"
echo ""
echo "Or in any new Claude chat ask:"
echo "    \"Recall my last 5 session logs\""
echo ""
