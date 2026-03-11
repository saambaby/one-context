#!/usr/bin/env bash
# Bootstrap AI context files for a new project.
#
# Usage (run from project root):
#   new-project [project-name] [stack-description]
#
# Example:
#   new-project tirza-api "TypeScript · NestJS · PostgreSQL"
#
# Requires: install.sh already run on this machine.

set -e

TEMPLATE_DIR="$HOME/.claude/templates/ai-context"
PROJECT_NAME="${1:-$(basename "$PWD")}"
STACK="${2:-}"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "✗ Templates not found at $TEMPLATE_DIR"
  echo "  Run install.sh first."
  exit 1
fi

# Guard against overwriting existing files
if [ -f "./CLAUDE.md" ]; then
  echo "✗ CLAUDE.md already exists. Aborting."
  exit 1
fi

# Copy templates
cp "$TEMPLATE_DIR/CLAUDE.md" ./CLAUDE.md
mkdir -p .cursor/rules
cp "$TEMPLATE_DIR/.cursor/rules/project.mdc" .cursor/rules/project.mdc

# Substitute placeholders
sed -i "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" CLAUDE.md
sed -i "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" .cursor/rules/project.mdc

if [ -n "$STACK" ]; then
  sed -i "s/\[STACK\]/$STACK/" CLAUDE.md
fi

echo ""
echo "✓ CLAUDE.md"
echo "✓ .cursor/rules/project.mdc  (@CLAUDE.md — Cursor reads the same file)"
echo ""
echo "Memory is global via MCP (~/.mcp-memory/). Nothing extra to set up."
echo ""
echo "Next — open Claude Code and say:"
echo "  'Starting $PROJECT_NAME. Stack: ${STACK:-<your stack>}."
echo "   Help me fill in CLAUDE.md. Ask me what you need.'"
