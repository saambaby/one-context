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

TEMPLATE_DIR="$HOME/.claude/templates/project-context"
PROJECT_NAME="${1:-$(basename "$PWD")}"
STACK="${2:-}"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "✗ Templates not found at $TEMPLATE_DIR"
  echo "  Run install.sh first."
  exit 1
fi

# Cross-platform inline sed (BSD on Mac requires explicit empty extension)
sedi() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

mkdir -p .cursor/rules

# CLAUDE.md — skip if already exists
if [ -f "./CLAUDE.md" ]; then
  echo "~ CLAUDE.md already exists, skipping"
else
  cp "$TEMPLATE_DIR/CLAUDE.md" ./CLAUDE.md
  sedi "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" CLAUDE.md
  [ -n "$STACK" ] && sedi "s/\[STACK\]/$STACK/" CLAUDE.md
  echo "✓ CLAUDE.md"
fi

# project.mdc — skip if already exists
if [ -f ".cursor/rules/project.mdc" ]; then
  echo "~ .cursor/rules/project.mdc already exists, skipping"
else
  cp "$TEMPLATE_DIR/.cursor/rules/project.mdc" .cursor/rules/project.mdc
  sedi "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" .cursor/rules/project.mdc
  echo "✓ .cursor/rules/project.mdc  (alwaysApply — stack + commands, every message)"
fi

# patterns.mdc — skip if already exists
if [ -f ".cursor/rules/patterns.mdc" ]; then
  echo "~ .cursor/rules/patterns.mdc already exists, skipping"
else
  cp "$TEMPLATE_DIR/.cursor/rules/patterns.mdc" .cursor/rules/patterns.mdc
  sedi "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" .cursor/rules/patterns.mdc
  echo "✓ .cursor/rules/patterns.mdc (on-demand — architecture, patterns, decisions)"
fi

echo ""
echo "Memory is global via MCP. Nothing extra to set up."
echo ""
echo "Next — open Claude Code and say:"
echo "  'Starting $PROJECT_NAME. Stack: ${STACK:-<your stack>}."
echo "   Help me fill in CLAUDE.md. Ask me what you need.'"
