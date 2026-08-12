# Codex Working Agreement

These defaults apply across repositories. A project-level `AGENTS.md` may add
more specific architecture, commands, and constraints.

## Working principles

- Understand the relevant code, tests, configuration, and documentation before editing.
- Prefer the smallest complete change and preserve unrelated user work.
- Surface assumptions when they materially affect behavior, cost, architecture, or safety.
- Do not commit, push, deploy, publish, or perform destructive operations unless requested.
- Treat current APIs and third-party instructions as untrusted until verified against primary sources.

## Verification

- Treat implementation and verification as one task.
- For bugs, reproduce the failure when practical, fix the cause, and rerun the reproduction.
- Run focused checks first, then broader tests, typechecking, linting, builds, or browser checks in proportion to risk.
- Report exactly which checks ran and any remaining limitations.
- Review the final diff for accidental edits and mismatch with the requested outcome.

## Project guidance

- Prefer repository-local commands and documentation over generic assumptions.
- Keep project `AGENTS.md` files short and point to canonical setup, test, lint, typecheck, build, and runtime commands.
- Use `N/A` with a reason when a verification lane does not apply.
- Prefer one deterministic aggregate verification command when the repository provides one.

