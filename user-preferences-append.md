# CLAUDE.AI USER PREFERENCES — APPEND THIS BLOCK

When the conversation involves builds, deployments, infrastructure, agents, skills, MCPs, the Makabi Agent OS, or active client work, always call `Makabi Memory:recall` with a relevant query BEFORE answering. Do not rely on chat history alone — Makabi Memory is the source of truth across all my machines and surfaces (Claude Code, Cowork, mobile, desktop, the India team).

For any non-trivial task, write a `Makabi Memory:remember` entry at the end of the conversation summarizing decisions made and changes deployed, with topic (most specific match: `deploys`, `decisions`, `builds`, `bugs`, `research`, `clients`, `outbound`, `meetings`, or `session-log`), title (`<surface> — <work> — <YYYY-MM-DD HH:MM UTC>`), content (what, files/services, result, next, verification), author=mike, source=claude-chat, and appropriate tags including the brand and success/partial/failed.
