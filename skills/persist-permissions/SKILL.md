---
name: persist-permissions
description: Persist project permissions to global settings for cross-session use
triggers:
  - persist permissions
  - save permissions
---

# Persist Permissions Skill

Merges permission rules from the current project's `.claude/settings.local.json` into the global `~/.claude/settings.json` so they persist across sessions.

## Problem

When you grant permissions during a Claude Code session (like allowing `git commit` or `yarn lint`), they're stored in `.claude/settings.local.json` in your project. But if your session ends (e.g., authentication timeout), you lose those permissions and have to re-grant them.

This skill copies your project permissions to the global `~/.claude/settings.json` so they persist forever.

## Instructions

When invoked, perform these steps:

1. **Read project permissions** from `.claude/settings.local.json` in the current directory
2. **Read global settings** from `~/.claude/settings.json`
3. **Normalize permissions** - convert verbose entries to patterns:
   - `Bash(git commit -m "...")` → `Bash(git commit:*)`
   - `Bash(yarn install)` → `Bash(yarn install:*)`
   - `Bash(gh pr create ...)` → `Bash(gh pr:*)`
   - Keep entries already ending in `:*)` unchanged
4. **Filter valid permissions** - only include entries starting with `Bash(`, `Read`, `Edit`, `Write`, `Grep`, `Glob`, or `mcp__`
5. **Identify new permissions** that aren't already in global settings
6. **Show the user** what will be added and ask for confirmation
7. **Merge and save** to `~/.claude/settings.json`, preserving all existing settings

## Normalization patterns

| Input pattern | Normalized to |
|---------------|---------------|
| `Bash(git add ...)` | `Bash(git add:*)` |
| `Bash(git commit ...)` | `Bash(git commit:*)` |
| `Bash(git push ...)` | `Bash(git push:*)` |
| `Bash(git fetch ...)` | `Bash(git fetch:*)` |
| `Bash(git rebase ...)` | `Bash(git rebase:*)` |
| `Bash(git diff...)` | `Bash(git diff:*)` |
| `Bash(git status...)` | `Bash(git status:*)` |
| `Bash(git log...)` | `Bash(git log:*)` |
| `Bash(gh pr ...)` | `Bash(gh pr:*)` |
| `Bash(gh issue ...)` | `Bash(gh issue:*)` |
| `Bash(yarn install...)` | `Bash(yarn install:*)` |
| `Bash(yarn lint...)` | `Bash(yarn lint:*)` |
| `Bash(yarn build...)` | `Bash(yarn build:*)` |
| `Bash(yarn test...)` | `Bash(yarn test:*)` |
| `Bash(yarn typecheck...)` | `Bash(yarn typecheck:*)` |
| `Bash(yarn prettier...)` | `Bash(yarn prettier:*)` |
| `Bash(npm install...)` | `Bash(npm install:*)` |
| `Bash(npm run...)` | `Bash(npm run:*)` |
| `Bash(npm test...)` | `Bash(npm test:*)` |
| `Bash(kubectl logs...)` | `Bash(kubectl logs:*)` |
| `Bash(kubectl get...)` | `Bash(kubectl get:*)` |
| `Bash(kubectl describe...)` | `Bash(kubectl describe:*)` |
| `Bash(cat ...)` | `Bash(cat:*)` |

## Output format

Show the user a summary like:
```
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

After confirmation, update the global settings and confirm success.

## Usage

```
/persist-permissions
```

Run this from any project directory where you've granted permissions during your session.
