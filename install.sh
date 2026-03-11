#!/usr/bin/env bash
# One-time machine setup for one-context.
#
# What it does:
#   1. Copies templates to ~/.claude/templates/project-context/
#   2. Symlinks scripts into ~/.local/bin/ and makes them executable
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
TEMPLATE_DEST="$HOME/.claude/templates/project-context"

if [ -d "$TEMPLATE_DEST" ] && [ "$FORCE" = false ]; then
  echo "~ Templates already exist at $TEMPLATE_DEST (use --force to overwrite)"
else
  rm -rf "$TEMPLATE_DEST"
  cp -r "$REPO_DIR/templates/project-context" "$TEMPLATE_DEST"
  echo "✓ Templates → $TEMPLATE_DEST"
fi

# ── 2. Scripts ────────────────────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

for script in new-project update-context; do
  LINK_DEST="$BIN_DIR/$script"
  LINK_SRC="$REPO_DIR/scripts/$script.sh"
  chmod +x "$LINK_SRC"
  if [ -e "$LINK_DEST" ] && [ "$FORCE" = false ]; then
    echo "~ $LINK_DEST already exists (use --force to overwrite)"
  else
    ln -sf "$LINK_SRC" "$LINK_DEST"
    echo "✓ Script → $LINK_DEST (symlink)"
  fi
done

# Always write update-ai-setup with the current repo path baked in.
cat > "$BIN_DIR/update-ai-setup" <<EOF
#!/usr/bin/env bash
# Pull latest changes from the one-context repo and reinstall.
set -e
cd "$REPO_DIR"
git pull
./install.sh --force
EOF
chmod +x "$BIN_DIR/update-ai-setup"
echo "✓ Script → $BIN_DIR/update-ai-setup"

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
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo ""
  echo "  Add ~/.local/bin to your PATH:"
  echo "    echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc  # or ~/.zshrc"
fi

echo ""
echo "Done. Run 'new-project <name> \"<stack>\"' from any project root."
