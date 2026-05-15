## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, complete the local Beads workflow. This repository does not currently use a Git remote as part of the agent workflow, so do not require `git push`/`bd dolt push` unless the user explicitly asks for remote sync.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create `bd` issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work with `bd close`, update in-progress items as needed
4. **Let Beads handle task bookkeeping** - Use `bd` for issue status and its normal local commit/bookkeeping behavior
5. **Verify local state** - Check `bd ready`/`bd show` and `git status` so the handoff is accurate
6. **Hand off** - Summarize changed files, checks run, issue status, and any remaining work

**CRITICAL RULES:**
- Use `bd` as the source of truth for task state
- Do not attempt to push unless a remote is configured and the user explicitly requests it
- Do not block completion on missing Git/Dolt remotes
- Do not say work is pushed or remotely synced unless an explicit push actually succeeded