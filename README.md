# persist-permissions

A Claude Code plugin that persists project permissions to global settings for cross-session use.

## Problem

When you grant permissions during a Claude Code session (like allowing `git commit` or `yarn lint`), they're stored in `.claude/settings.local.json` in your project. But if your session ends (e.g., authentication timeout, context limit), you lose those permissions and have to re-grant them.

This plugin copies your project permissions to the global `~/.claude/settings.json` so they persist forever.

## Installation

```bash
# Add the marketplace
/plugin marketplace add https://github.com/dansherpa/persist-permissions-plugin

# Install the plugin
/plugin install persist-permissions
```

Or install directly from a local directory:
```bash
claude --plugin-dir /path/to/persist-permissions-plugin
```

### First-time Bootstrap

**Important:** Installing a plugin requires restarting Claude Code, which loses your current session's permissions - the very thing you want to save!

Run the bootstrap script **before** restarting to save your permissions first:

```bash
# From your project directory (where you've granted permissions)
curl -fsSL https://raw.githubusercontent.com/dansherpa/persist-permissions-plugin/main/scripts/persist-permissions.sh | bash

# Or if you've cloned the repo:
./scripts/persist-permissions.sh
```

After that, restart Claude Code and use `/persist-permissions` going forward.

## Usage

From any project directory where you've granted permissions:

```
/persist-permissions
```

The skill will:
1. Read your project's `.claude/settings.local.json`
2. Normalize verbose entries to wildcard patterns (e.g., `Bash(git commit -m "...")` → `Bash(git commit:*)`)
3. Filter out invalid entries (junk from multi-line commands)
4. Show you what will be added
5. Ask for confirmation before saving to `~/.claude/settings.json`

## Example

```
/persist-permissions

Processing permissions from .claude/settings.local.json...

New permissions to add:
  + Bash(git commit:*)
  + Bash(gh pr:*)
  + Bash(yarn lint:*)

Already in global settings:
  - Bash(git push:*)

Skipped 5 invalid entries (junk from multi-line commands)

Add these 3 permissions to ~/.claude/settings.json? [y/N]
```

## Supported normalizations

The skill converts verbose permission entries to wildcard patterns:

| Verbose entry | Normalized pattern |
|---------------|-------------------|
| `Bash(git commit -m "fix: ...")` | `Bash(git commit:*)` |
| `Bash(yarn install)` | `Bash(yarn install:*)` |
| `Bash(gh pr create --title ...)` | `Bash(gh pr:*)` |
| `Bash(kubectl logs -f pod/...)` | `Bash(kubectl logs:*)` |

## License

MIT
