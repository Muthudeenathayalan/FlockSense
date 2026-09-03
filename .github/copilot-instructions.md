<!-- Auto-generated: guidance for AI coding agents working in this repo -->
# Copilot / AI Agent Instructions

Purpose
- Help AI coding assistants be immediately productive in this workspace.

What this repo contains
- Top-level notes: `idea.md` and `setup.md` (see both for context and intent).
- There is no build system, source code, or tests checked in currently — treat this as a notes/idea repository unless the user supplies additional files.

Primary goals for the agent
- Read `idea.md` and `setup.md` first to understand the author's intent and any setup notes.
- Ask clarifying questions before making structural changes (e.g., adding new toolchains, languages, or CI) because the repo currently lacks explicit build/test conventions.

How to act (concise rules)
- If asked to implement code or features, request the target language, build/test commands, and preferred repo layout before creating multiple files.
- When editing `idea.md` or `setup.md`, preserve plain-markdown bullet structure and keep changes minimal and reversible.
- Do not assume package managers, CI, or linters — confirm before adding `package.json`, `pyproject.toml`, `.github/workflows`, or similar files.

Examples (project-specific)
- To add a small runnable example, propose adding a new top-level folder (e.g., `src/`), include a minimal `README.md` explaining how to run it, and provide explicit commands for the user's OS (Windows). Show exact commands you expect the user to run.
- If you create CI, include sample run commands and explain any required secrets or environment variables in `setup.md`.

Developer workflows & checks
- Always request the exact build/test commands before running or proposing automation; the repository currently has no discoverable commands.
- When making edits, include a short summary line in the patch/commit message and ask the user to run or validate the change locally (we cannot assume remote execution).

Conventions & preferences
- Keep changes minimal and tightly scoped — this repo appears to be idea/setup notes rather than production code.
- Prefer explicit questions over assumptions. For example: "Should I add a Python example using `venv` or a Node example with `npm`?"

When to propose larger scaffolding
- Only scaffold language-specific projects (tooling, CI, tests) after the user confirms intended stack and provides or permits example commands.

References
- Start with `idea.md` and `setup.md` for context.

If anything here is unclear or you want the instructions to be stricter/looser, ask the repo owner for clarification and I'll update this file accordingly.
