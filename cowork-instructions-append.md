# COWORK INSTRUCTIONS — APPEND THIS BLOCK TO YOUR EXISTING COWORK INSTRUCTIONS

## MANDATORY MEMORY DISCIPLINE

At the end of every Cowork session, before terminating, you MUST call `Makabi Memory:remember` to log what was done. This is non-negotiable.

Required fields:
- **topic** — pick from `session-log`, `deploys`, `decisions`, `builds`, `bugs`, `research`, `clients`, `outbound`, `meetings`
- **title** — `cowork-<machine> — <work> — <YYYY-MM-DD HH:MM UTC>`
- **content** — what was done, files/services touched, result, what's next, how to verify
- **author** — `mike` (or whichever team member is running the session)
- **source** — machine identity (`mike-laptop-cowork`, `mike-desktop-cowork`, `cowork-mobile`)
- **tags** — `[auto-saved, cowork, <brand>, success|partial|failed]`

If the session deployed anything to production, also write a second memory under `topic=deploys` with repo, branch, commit hash, deploy target, release ID, smoke test results.

The full protocol is in Makabi Memory under name `mandatory-memory-discipline`. Call `Makabi Memory:get_protocol(name="mandatory-memory-discipline")` for the full spec.

At the **start** of any non-trivial Cowork session, call `Makabi Memory:recall` first to load relevant prior context. Memory is the source of truth — ahead of any local file state.

This rule applies on every machine, on every device, every time. Mike's machines, Sanjeev's team in India, mobile, desktop, ephemeral cloud sandboxes — everywhere.
