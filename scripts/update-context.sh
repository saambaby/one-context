#!/usr/bin/env bash
# Review and update context files as a project evolves.
#
# Usage (run from project root):
#   update-context [project-name]
#
# Launches Claude Code with a structured prompt that:
#   1. Pulls MCP memory decisions worth promoting to context files
#   2. Scans tracked files (git ls-files) for config/tooling changes
#   3. Flags stale entries in either file
#   4. Applies edits — CLAUDE.md stays minimal, patterns.mdc gets the rest
#
# Requires: install.sh already run, CLAUDE.md present in current directory.

set -e

PROJECT_NAME="${1:-$(basename "$PWD")}"

if [ ! -f "./CLAUDE.md" ]; then
  echo "✗ No CLAUDE.md found in current directory."
  echo "  Run 'new-project $PROJECT_NAME' first, or cd to your project root."
  exit 1
fi

# Ensure patterns.mdc exists — create it if this is an older project that predates the split
PATTERNS_FILE=".cursor/rules/patterns.mdc"
if [ ! -f "$PATTERNS_FILE" ]; then
  TEMPLATE_DIR="$HOME/.claude/templates/project-context"
  mkdir -p .cursor/rules
  cp "$TEMPLATE_DIR/.cursor/rules/patterns.mdc" "$PATTERNS_FILE"
  sed -i "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$PATTERNS_FILE" 2>/dev/null || \
    sed -i '' "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$PATTERNS_FILE"
  echo "✓ Created .cursor/rules/patterns.mdc"
fi

PROMPT="Review and update context files for the '$PROJECT_NAME' project.

There are two context files with different roles:
- \`CLAUDE.md\` — loaded in every Cursor message (hard limit: 30 lines). Stack, commands, memory instruction only.
- \`.cursor/rules/patterns.mdc\` — loaded on demand when relevant. Architecture, patterns, key decisions go here.

Work through these steps in order:

1. **Read both files** — load \`CLAUDE.md\` and \`.cursor/rules/patterns.mdc\`.

2. **Audit memory** — search MCP memory for '$PROJECT_NAME'. For each entry decide:
   - Stable pattern or convention → promote to \`patterns.mdc\`, then delete from memory
   - Architectural decision → promote to \`patterns.mdc\`, then delete from memory
   - Resolved TODO or completed work → delete from memory
   - Superseded by a newer entry → delete the old one
   - Actively in-flight → leave it

3. **Scan the repo** — run \`git ls-files\` to list tracked files. Read only:
   - Top-level config files (package.json, Cargo.toml, pyproject.toml, Makefile, docker-compose.yml, .env.example, etc.)
   - Do not read source files unless a command or path in CLAUDE.md needs verifying.
   Find: commands that differ from what's documented, env vars missing from CLAUDE.md, new top-level directories not yet mentioned.

4. **Flag stale entries** — anything in either file that no longer matches reality: renamed files, removed commands, outdated patterns.

5. **Apply edits**:
   - \`CLAUDE.md\`: stack, commands, memory instruction only. Hard limit: 30 lines. Move anything else to \`patterns.mdc\`.
   - \`.cursor/rules/patterns.mdc\`: architecture, patterns, decisions. No size limit but keep entries concise.

6. **Summarise** — print a brief bullet list of what was added, changed, and removed in each file."

echo ""
echo "Updating context for '$PROJECT_NAME'..."
echo ""

claude -p --permission-mode acceptEdits "$PROMPT"
