#!/bin/bash
# persist-permissions.sh
# Bootstrap script - run this BEFORE restarting Claude Code to persist your permissions.
# After the plugin is installed, use /persist-permissions instead.

set -e

GLOBAL_SETTINGS="$HOME/.claude/settings.json"
LOCAL_SETTINGS=".claude/settings.local.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Persist Permissions (Bootstrap) ===${NC}"
echo

if [[ ! -f "$LOCAL_SETTINGS" ]]; then
    echo -e "${RED}Error: No local settings found at $LOCAL_SETTINGS${NC}"
    echo "Run this from a project directory where you've granted permissions."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required. Install with: brew install jq${NC}"
    exit 1
fi

LOCAL_PERMS=$(jq -r '.permissions.allow // []' "$LOCAL_SETTINGS" 2>/dev/null)
if [[ "$LOCAL_PERMS" == "[]" ]]; then
    echo -e "${YELLOW}No permissions found in local settings.${NC}"
    exit 0
fi

# Validation: only process entries starting with valid tool prefixes
is_valid() {
    [[ "$1" == Bash\(* ]] || [[ "$1" == "Read" ]] || [[ "$1" == "Edit" ]] || \
    [[ "$1" == "Write" ]] || [[ "$1" == "Grep" ]] || [[ "$1" == "Glob" ]] || [[ "$1" == mcp__* ]]
}

# Normalize verbose entries to patterns
normalize() {
    local p="$1"
    [[ "$p" == *":*)" ]] && { echo "$p"; return; }

    case "$p" in
        'Bash(git add '*) echo "Bash(git add:*)" ;;
        'Bash(git commit '*) echo "Bash(git commit:*)" ;;
        'Bash(git push '*) echo "Bash(git push:*)" ;;
        'Bash(git fetch '*) echo "Bash(git fetch:*)" ;;
        'Bash(git rebase '*) echo "Bash(git rebase:*)" ;;
        'Bash(git diff'*) echo "Bash(git diff:*)" ;;
        'Bash(git status'*) echo "Bash(git status:*)" ;;
        'Bash(git log'*) echo "Bash(git log:*)" ;;
        'Bash(gh pr '*) echo "Bash(gh pr:*)" ;;
        'Bash(gh issue '*) echo "Bash(gh issue:*)" ;;
        'Bash(yarn install'*) echo "Bash(yarn install:*)" ;;
        'Bash(yarn lint'*) echo "Bash(yarn lint:*)" ;;
        'Bash(yarn build'*) echo "Bash(yarn build:*)" ;;
        'Bash(yarn test'*) echo "Bash(yarn test:*)" ;;
        'Bash(yarn typecheck'*) echo "Bash(yarn typecheck:*)" ;;
        'Bash(yarn prettier'*) echo "Bash(yarn prettier:*)" ;;
        'Bash(npm install'*) echo "Bash(npm install:*)" ;;
        'Bash(npm run'*) echo "Bash(npm run:*)" ;;
        'Bash(npm test'*) echo "Bash(npm test:*)" ;;
        'Bash(kubectl logs'*) echo "Bash(kubectl logs:*)" ;;
        'Bash(kubectl get'*) echo "Bash(kubectl get:*)" ;;
        'Bash(kubectl describe'*) echo "Bash(kubectl describe:*)" ;;
        'Bash(cat '*|'Bash(cat:'*) echo "Bash(cat:*)" ;;
        *) echo "$p" ;;
    esac
}

# Read existing global permissions
if [[ -f "$GLOBAL_SETTINGS" ]]; then
    GLOBAL_PERMS=$(jq -r '.permissions.allow // []' "$GLOBAL_SETTINGS" 2>/dev/null)
else
    GLOBAL_PERMS="[]"
fi

echo -e "${BLUE}Processing permissions...${NC}"
echo

NEW_PERMS_JSON="[]"
SKIPPED=0

while IFS= read -r perm; do
    [[ -z "$perm" ]] && continue

    if ! is_valid "$perm"; then
        ((SKIPPED++))
        continue
    fi

    normalized=$(normalize "$perm")

    in_global=$(echo "$GLOBAL_PERMS" | jq -e --arg p "$normalized" 'index($p) != null' 2>/dev/null && echo "yes" || echo "no")
    in_new=$(echo "$NEW_PERMS_JSON" | jq -e --arg p "$normalized" 'index($p) != null' 2>/dev/null && echo "yes" || echo "no")

    if [[ "$in_global" == "yes" ]]; then
        echo -e "  ${YELLOW}[exists]${NC} $normalized"
    elif [[ "$in_new" == "yes" ]]; then
        : # skip duplicates silently
    else
        echo -e "  ${GREEN}[new]${NC} $normalized"
        NEW_PERMS_JSON=$(echo "$NEW_PERMS_JSON" | jq --arg p "$normalized" '. + [$p]')
    fi
done < <(echo "$LOCAL_PERMS" | jq -r '.[]')

[[ $SKIPPED -gt 0 ]] && echo -e "\n  ${YELLOW}(Skipped $SKIPPED invalid entries)${NC}"
echo

NEW_COUNT=$(echo "$NEW_PERMS_JSON" | jq 'length')
if [[ "$NEW_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}All permissions already in global settings.${NC}"
    exit 0
fi

echo -e "${BLUE}Will add $NEW_COUNT permission(s) to $GLOBAL_SETTINGS${NC}"
echo
read -p "Apply these changes? [y/N] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

if [[ -f "$GLOBAL_SETTINGS" ]]; then
    UPDATED=$(jq --argjson new "$NEW_PERMS_JSON" \
        '.permissions.allow = ((.permissions.allow // []) + $new | unique)' \
        "$GLOBAL_SETTINGS")
else
    mkdir -p "$(dirname "$GLOBAL_SETTINGS")"
    UPDATED=$(jq -n --argjson new "$NEW_PERMS_JSON" '{"permissions": {"allow": $new}}')
fi

echo "$UPDATED" > "$GLOBAL_SETTINGS"
echo -e "${GREEN}Done! Permissions saved.${NC}"
