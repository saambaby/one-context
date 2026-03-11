#!/usr/bin/env bash
# Promote MCP memory decisions into context files.
#
# Usage (run from project root):
#   update-context [project-name]
#
# Reads MCP memory and promotes settled decisions/patterns into the right file.
# Does NOT audit or fix the repo. Run manually when you want to flush memory.
#
# Requires: install.sh already run, CLAUDE.md present in current directory.

set -e

PROJECT_NAME="${1:-$(basename "$PWD")}"

if [ ! -f "./CLAUDE.md" ]; then
  echo "✗ No CLAUDE.md found in current directory."
  echo "  Run 'new-project $PROJECT_NAME' first, or cd to your project root."
  exit 1
fi

# Ensure patterns.mdc exists — create it for projects that predate the split
PATTERNS_FILE=".cursor/rules/patterns.mdc"
if [ ! -f "$PATTERNS_FILE" ]; then
  TEMPLATE_DIR="$HOME/.claude/templates/project-context"
  mkdir -p .cursor/rules
  cp "$TEMPLATE_DIR/.cursor/rules/patterns.mdc" "$PATTERNS_FILE"
  sed -i "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$PATTERNS_FILE" 2>/dev/null || \
    sed -i '' "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$PATTERNS_FILE"
  echo "✓ Created .cursor/rules/patterns.mdc"
fi

PROMPT="Promote MCP memory into context files for '$PROJECT_NAME'. Do not audit the repo or suggest fixes.

Files:
- \`CLAUDE.md\` — stack + commands only, hard limit 30 lines
- \`.cursor/rules/patterns.mdc\` — architecture, patterns, decisions

Steps:
1. Read both files.
2. Search MCP memory for '$PROJECT_NAME'. For each entry:
   - Stable pattern or decision → write it into \`patterns.mdc\`, delete from memory
   - Resolved or completed item → delete from memory
   - Superseded by a newer entry → delete the old one
   - Actively in-flight → leave it unchanged
3. If \`CLAUDE.md\` exceeds 30 lines, move the excess into \`patterns.mdc\`.
4. If nothing needed changing, say 'No updates needed' and stop.
5. Otherwise print a brief bullet list of what changed."

echo ""
echo "Updating context for '$PROJECT_NAME'..."
echo ""

claude -p --permission-mode bypassPermissions --no-session-persistence \
  --allowedTools "Read,Edit,mcp__memory__search_nodes,mcp__memory__open_nodes,mcp__memory__read_graph,mcp__memory__create_entities,mcp__memory__add_observations,mcp__memory__create_relations,mcp__memory__delete_entities,mcp__memory__delete_observations,mcp__memory__delete_relations" \
  "$PROMPT"
