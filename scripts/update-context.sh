#!/usr/bin/env bash
# Review and update CLAUDE.md as a project evolves.
#
# Usage (run from project root):
#   update-context [project-name]
#
# Launches Claude Code with a structured prompt that:
#   1. Pulls MCP memory decisions worth promoting to CLAUDE.md
#   2. Scans the repo for new/changed structure not yet documented
#   3. Flags stale entries (dead files, renamed commands, outdated patterns)
#   4. Proposes and applies edits — you confirm before anything changes
#
# Requires: install.sh already run, CLAUDE.md present in current directory.

set -e

PROJECT_NAME="${1:-$(basename "$PWD")}"

if [ ! -f "./CLAUDE.md" ]; then
  echo "✗ No CLAUDE.md found in current directory."
  echo "  Run 'new-project $PROJECT_NAME' first, or cd to your project root."
  exit 1
fi

PROMPT="Review and update CLAUDE.md for the '$PROJECT_NAME' project.

Work through these steps in order:

1. **Read CLAUDE.md** — load the current content so you know what's already documented.

2. **Audit memory** — search MCP memory for '$PROJECT_NAME'. For each entry decide:
   - Stable decision or pattern → promote to CLAUDE.md, then delete from memory
   - Resolved TODO or completed work → delete from memory (it's done)
   - Superseded or contradicted by newer entries → delete the old one
   - Active / still relevant session state → leave it
   The goal is a small memory graph of things that are genuinely in-flight.

3. **Scan the repo** — look at the actual directory structure, key files, and any config/tooling files (package.json, Cargo.toml, pyproject.toml, Makefile, docker-compose.yml, etc.). Find:
   - New modules, packages, or directories not yet in CLAUDE.md
   - Build/run/test commands that differ from what's documented
   - Environment variables defined in .env.example or config files but missing from CLAUDE.md

4. **Flag stale entries** — identify anything in CLAUDE.md that no longer matches reality: renamed files, removed commands, outdated patterns, resolved TODO items.

5. **Propose edits** — summarise what you'd add, change, and remove. If CLAUDE.md already exceeds ~80 lines of real content, propose moving the heaviest section into a focused topic file (e.g. \`.cursor/rules/api.mdc\`) and replacing it with a one-line reference. Wait for my confirmation before writing anything.

6. **Apply** — once I confirm, make all changes. Keep CLAUDE.md concise; it's a reference document, not a tutorial."

echo ""
echo "Launching Claude Code to review CLAUDE.md for '$PROJECT_NAME'..."
echo ""

exec claude "$PROMPT"
