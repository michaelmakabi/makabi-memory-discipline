# Makabi Mandatory Memory Discipline — Install Bundle

**Effective:** 2026-05-06
**Authority:** Master Makabi
**Scope:** Every machine that runs Claude Code or Cowork — anywhere.

## What this does

Forces every Claude Code and Cowork session — on any machine, anywhere — to write back to your cloud Makabi Memory at session end. Three layers of enforcement so it cannot be skipped.

## Files in this bundle

| File | Where it goes | Purpose |
|---|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global system prompt — read by every Claude Code session at startup |
| `session-end.sh` | `~/.claude/hooks/session-end.sh` | Auto-runs at end of every session, writes fallback memory |
| `settings.json` | `~/.claude/settings.json` | Registers the SessionEnd hook with Claude Code |
| `cowork-instructions-append.md` | Paste into Cowork Settings → Instructions | Adds the rule to Cowork's persistent prompt |
| `user-preferences-append.md` | Paste into Claude.ai Settings → Profile → Preferences | Adds the rule to Claude chat |
| `install.sh` | Run once per machine | One-shot installer |

## One-line install (per machine)

```bash
git clone https://github.com/michaelmakabi/makabi-memory-discipline.git
cd makabi-memory-discipline && bash install.sh
```

## After installing

1. **Cowork** — open Cowork settings on each device, paste `cowork-instructions-append.md` contents at the bottom of your existing Cowork Instructions. Save.
2. **Claude chat** — open https://claude.ai → Settings → Profile → User Preferences. Append `user-preferences-append.md` contents to your existing preferences. Save.
3. **Verify** — start any Claude Code session, do anything trivial, end it. Then check:
   ```bash
   cat ~/.claude/last-memory-write.log
   ```
   You should see a successful write to `https://memory.mtip.ai/mcp/tools/remember`.

## Verification from anywhere

In any new Claude chat, ask: "Recall my last 5 session logs." Claude will call `Makabi Memory:recall(query="session log", topic="session-log", limit=5)` and you'll see entries from each machine you've used.

## Architecture

```
                    Master Makabi (you)
                          │
                ┌─────────┴─────────┐
                │                   │
        Claude Code              Cowork
        (terminal,              (desktop +
         any machine)            mobile)
                │                   │
                ├──── CLAUDE.md ────┤
                │   (rule layer)    │
                │                   │
                ├── SessionEnd ─────┤
                │  hook (backstop)  │
                │                   │
                └─────────┬─────────┘
                          │
                          ▼
              https://memory.mtip.ai/mcp
                  (cloud memory —
                  source of truth)
                          │
                          ▼
                    Claude chat
                  (recalls before
                    answering)
```

## Why open mode (no token)

Master Makabi chose open mode for speed of rollout. Trade-off: anyone with shell access on the machine can write to Memory. Acceptable risk for personal/team machines. Can be upgraded to token-gated by setting `MAKABI_MEMORY_TOKEN` env var on each machine and editing `session-end.sh` to pass `Authorization: Bearer $MAKABI_MEMORY_TOKEN`.

## Rolling back

```bash
cd ~/.claude
mv CLAUDE.md.bak.<latest> CLAUDE.md
rm hooks/session-end.sh
mv settings.json.bak.<latest> settings.json
```
