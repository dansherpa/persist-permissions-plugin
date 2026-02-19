# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code plugin that persists project-local permissions (`.claude/settings.local.json`) to global settings (`~/.claude/settings.json`) so they survive session restarts.

## Architecture

```
persist-permissions-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (name, version, metadata)
├── skills/
│   └── persist-permissions/
│       └── SKILL.md         # Skill definition and instructions for Claude
└── scripts/
    └── persist-permissions.sh   # Bootstrap script (runs outside Claude)
```

**Two entry points:**
1. **Skill** (`/persist-permissions`) - Used within Claude Code after plugin installation. Instructions are in `SKILL.md`.
2. **Bootstrap script** - Used before plugin installation to save permissions that would otherwise be lost on restart.

## Key Files

- `skills/persist-permissions/SKILL.md` - The skill prompt that tells Claude how to perform the permission merge. Contains normalization patterns and output format.
- `scripts/persist-permissions.sh` - Standalone bash script using `jq` for JSON manipulation. Mirrors the skill's logic.

## Permission Normalization

Both entry points normalize verbose permission entries to wildcard patterns:
- `Bash(git commit -m "fix: ...")` → `Bash(git commit:*)`
- `Bash(yarn lint --fix)` → `Bash(yarn lint:*)`

Valid prefixes: `Bash(`, `Read`, `Edit`, `Write`, `Grep`, `Glob`, `mcp__`

## Testing Changes

To test the bootstrap script:
```bash
cd /some/project/with/.claude/settings.local.json
./scripts/persist-permissions.sh
```

To test the skill, install the plugin and run `/persist-permissions` from a project directory.
