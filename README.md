# one-context

Shared AI context for Claude Code and Cursor — one setup, any machine.

Both tools read the same `CLAUDE.md` from your repo. Both connect to the same
MCP memory server. You maintain one file per project and memory follows you
everywhere.

---

## How it works

```
Your repo
├── CLAUDE.md                      ← stack, commands, patterns (you maintain this)
└── .cursor/rules/project.mdc      ← @CLAUDE.md  (Cursor reads the same file)

Your machine (global)
└── ~/.one-context/                ← knowledge graph: todos, decisions, build state
      registered with Claude Code (user scope)
      registered with Cursor       (~/.cursor/mcp.json)
```

**Static context** (`CLAUDE.md`) — what doesn't change mid-session: stack,
commands, key patterns. Lives in the repo so it's versioned. Both tools load it
automatically on every session.

**Dynamic memory** (MCP) — what evolves during a session: open todos, decisions,
current build state. Stored globally, persists across sessions and projects.

---

## Prerequisites

- [Claude Code](https://claude.ai/code) installed and on your `$PATH`
- [Cursor](https://www.cursor.com/) installed (optional)
- Node.js / `npx` available

---

## Install (run once per machine)

```bash
git clone <this-repo>
cd one-context
./install.sh
```

What `install.sh` does:

1. Copies `templates/project-context/` to `~/.claude/templates/project-context/`
2. Symlinks scripts into `~/.local/bin/` and makes them executable
3. Registers the memory MCP with Claude Code (user scope)
4. Writes `~/.cursor/mcp.json` pointing to the same memory path
5. Creates `~/.local/bin/update-ai-setup` for keeping the install current

Re-running is safe — nothing is overwritten unless you pass `--force`.

If `~/.local/bin` is not in your `PATH`, the installer will tell you what to add
to your `.bashrc` / `.zshrc`.

### Using a shared memory location

To sync memory across machines via a shared folder (Dropbox, etc.), set
`MCP_MEMORY_PATH` before running:

```bash
MCP_MEMORY_PATH=~/Dropbox/.one-context ./install.sh
```

If the memory MCP is already registered in Claude Code, the installer reads its
configured path automatically and uses that for Cursor too — both tools always
point to the same location.

---

## Update the install

When changes are pushed to this repo, run on any machine:

```bash
update-ai-setup
```

This pulls the latest from the repo and reinstalls with `--force`. The repo path
is baked in at install time.

---

## Starting a new project

Run from the root of your project directory:

```bash
cd ~/development/my-project
new-project my-project "TypeScript · NestJS · PostgreSQL"
```

This creates:

```
my-project/
├── CLAUDE.md                      ← pre-filled with project name and stack
└── .cursor/rules/project.mdc      ← loads CLAUDE.md in Cursor (alwaysApply)
```

Then open Claude Code and say:

> "We're starting my-project. Stack: TypeScript · NestJS · PostgreSQL.
> Help me fill in CLAUDE.md — ask me anything you need."

Commit `CLAUDE.md` when it looks right.

---

## Day-to-day workflow

### Claude Code

Reads `CLAUDE.md` automatically on every session. At session start it also
searches MCP memory for the project to recall open todos and recent decisions.

To save something during a session:

> "Remember that we decided to use ULIDs for all primary keys."

### Cursor

Loads `CLAUDE.md` via `project.mdc` (`alwaysApply: true`) on every conversation.
Also reads the same MCP memory since it's the same instruction in `CLAUDE.md`.

> Note: Cursor follows the memory instruction via the rule — it relies on the
> model following it, not a hard guarantee.

---

## Keeping CLAUDE.md current

`CLAUDE.md` starts minimal (project name, stack, commands). Add sections as the
project grows. Run `update-context` periodically to promote stable decisions from
MCP memory into the file and flag anything stale.

```bash
cd ~/development/my-project
update-context my-project
```

Claude will:
1. Read the current `CLAUDE.md`
2. Audit MCP memory — promote stable decisions, clean up resolved items
3. Scan the repo for new structure, commands, or env vars not yet documented
4. Flag stale entries — dead files, renamed commands, resolved TODOs
5. Propose all changes and wait for your confirmation before writing

**Good things to put in:**
- Non-obvious architecture decisions and the reason behind them
- Patterns that must be followed (naming, error handling, file layout)
- Commands to build, run, test, lint
- Key files and what they do
- Environment variables and what they control

**Keep out:**
- Things that change every session (use MCP memory for those)
- Standard framework conventions any engineer would assume
- Sections you haven't filled in yet — delete placeholders, add them when real

---

## Repo structure

```
one-context/
├── install.sh                     ← one-time machine setup
├── scripts/
│   ├── new-project.sh             ← per-project bootstrap
│   └── update-context.sh          ← keep CLAUDE.md current as project evolves
└── templates/
    └── project-context/
        ├── CLAUDE.md              ← minimal project template (name, stack, commands)
        └── .cursor/
            └── rules/
                └── project.mdc   ← Cursor rule: @CLAUDE.md (alwaysApply)
```

---

## Caveats

- **Cursor memory is rule-driven.** The memory instruction lives in `CLAUDE.md`
  and is injected via `project.mdc`. It relies on the model following the rule —
  not a hard guarantee like Claude Code's native `CLAUDE.md` support.
- **Concurrent writes.** Both tools spawn separate MCP server processes pointing
  at the same file. Simultaneous writes at the exact same instant could corrupt
  the memory file. Unlikely in practice.
# one-context
