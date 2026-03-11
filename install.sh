#!/usr/bin/env bash
# One-time machine setup for one-context.
#
# What it does:
#   1. Copies templates to ~/.claude/templates/ai-context/
#   2. Copies scripts to ~/scripts/ and makes them executable
#   3. Registers the memory MCP with Claude Code (user scope)
#   4. Writes ~/.cursor/mcp.json pointing to the same memory path
#
# Safe to re-run — existing files are not overwritten unless --force is passed.
#
# To use a shared/synced memory location (e.g. Dropbox), set MCP_MEMORY_PATH
# before running:
#   MCP_MEMORY_PATH=~/Dropbox/.one-context ./install.sh

set -e

FORCE=false
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE=true
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_MEMORY_PATH="${MCP_MEMORY_PATH:-$HOME/.one-context}"

# ── 1. Templates ──────────────────────────────────────────────────────────────
TEMPLATE_DEST="$HOME/.claude/templates/ai-context"

if [ -d "$TEMPLATE_DEST" ] && [ "$FORCE" = false ]; then
  echo "~ Templates already exist at $TEMPLATE_DEST (use --force to overwrite)"
else
  rm -rf "$TEMPLATE_DEST"
  cp -r "$REPO_DIR/templates/ai-context" "$TEMPLATE_DEST"
  echo "✓ Templates → $TEMPLATE_DEST"
fi

# ── 2. Scripts ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/scripts"

for script in new-project update-context; do
  SCRIPT_DEST="$HOME/scripts/$script"
  if [ -f "$SCRIPT_DEST" ] && [ "$FORCE" = false ]; then
    echo "~ $SCRIPT_DEST already exists (use --force to overwrite)"
  else
    cp "$REPO_DIR/scripts/$script.sh" "$SCRIPT_DEST"
    chmod +x "$SCRIPT_DEST"
    echo "✓ Script → $SCRIPT_DEST"
  fi
done

# Always write update-ai-setup with the current repo path baked in.
cat > "$HOME/scripts/update-ai-setup" <<EOF
#!/usr/bin/env bash
# Pull latest changes from the one-context repo and reinstall.
set -e
cd "$REPO_DIR"
git pull
./install.sh --force
EOF
chmod +x "$HOME/scripts/update-ai-setup"
echo "✓ Script → $HOME/scripts/update-ai-setup"

# ── 3. Claude Code MCP (user scope) ──────────────────────────────────────────
# If already registered, extract the configured path so Cursor stays in sync.
EXISTING_PATH=$(python3 -c "
import json, os, sys
cfg = os.path.expanduser('~/.claude.json')
try:
    data = json.load(open(cfg))
    servers = data.get('mcpServers', {})
    args = servers.get('memory', {}).get('args', [])
    idx = args.index('--memory-path') if '--memory-path' in args else -1
    print(args[idx + 1] if idx >= 0 else '')
except:
    print('')
" 2>/dev/null)

if [ -n "$EXISTING_PATH" ]; then
  MCP_MEMORY_PATH="$EXISTING_PATH"
  echo "~ Memory MCP already registered with Claude Code → $MCP_MEMORY_PATH"
else
  claude mcp add --scope user memory -- \
    npx -y @modelcontextprotocol/server-memory --memory-path "$MCP_MEMORY_PATH"
  echo "✓ Memory MCP registered with Claude Code → $MCP_MEMORY_PATH"
fi

# ── 4. Cursor MCP ─────────────────────────────────────────────────────────────
# Always written to match the Claude Code memory path.
CURSOR_MCP="$HOME/.cursor/mcp.json"
mkdir -p "$HOME/.cursor"

if [ -f "$CURSOR_MCP" ] && [ "$FORCE" = false ]; then
  echo "~ $CURSOR_MCP already exists (use --force to overwrite)"
else
  cat > "$CURSOR_MCP" <<EOF
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory", "--memory-path", "$MCP_MEMORY_PATH"]
    }
  }
}
EOF
  echo "✓ Cursor MCP config → $CURSOR_MCP"
fi

# ── PATH hint ─────────────────────────────────────────────────────────────────
if ! echo "$PATH" | grep -q "$HOME/scripts"; then
  echo ""
  echo "  Add ~/scripts to your PATH:"
  echo "    echo 'export PATH=\"\$HOME/scripts:\$PATH\"' >> ~/.bashrc  # or ~/.zshrc"
fi

echo ""
echo "Done. Run 'new-project <name> \"<stack>\"' from any project root."
