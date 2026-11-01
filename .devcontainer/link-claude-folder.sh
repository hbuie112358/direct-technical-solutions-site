#!/usr/bin/env bash
# Runs in the container after every start (devcontainer.json postStartCommand).
#
# The container keeps its own Claude folder (CLAUDE_CONFIG_DIR, a named volume) so that its login
# never replaces the host's. The shared parts live in the host's ~/.claude, mounted at
# /root/.claude: this script links the rule files, settings.json, hooks/ and this project's own
# folder under projects/ (sessions, memory, time log) into the container's folder. Nothing of
# another project is linked. See ~/.claude/DEVCONTAINER_SETUP.md, rule 5.
#
# Usage: link-claude-folder.sh <workspace path in the container>

set -euo pipefail

readonly SHARED_CLAUDE_FOLDER=/root/.claude
# Claude Code names a project's folder after its path, every non-alphanumeric character as '-'.
readonly NON_ALPHANUMERIC='[^A-Za-z0-9]'

workspace="${1:?usage: link-claude-folder.sh <workspace path in the container>}"
own_claude_folder="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR is not set in the container}"
project_key="$(sed "s/${NON_ALPHANUMERIC}/-/g" <<<"$workspace")"

[[ -d "$SHARED_CLAUDE_FOLDER" ]] || { echo "link-claude-folder: ${SHARED_CLAUDE_FOLDER} is not mounted" >&2; exit 1; }
mkdir -p "$own_claude_folder/projects" "$SHARED_CLAUDE_FOLDER/projects/$project_key"

for rule_file in "$SHARED_CLAUDE_FOLDER"/*.md; do
    ln -sfn "$rule_file" "$own_claude_folder/$(basename "$rule_file")"
done
ln -sfn "$SHARED_CLAUDE_FOLDER/settings.json" "$own_claude_folder/settings.json"
ln -sfn "$SHARED_CLAUDE_FOLDER/hooks" "$own_claude_folder/hooks"
ln -sfn "$SHARED_CLAUDE_FOLDER/projects/$project_key" "$own_claude_folder/projects/$project_key"

# A rule file removed on the host leaves a dangling link behind; remove those.
find "$own_claude_folder" -maxdepth 1 -xtype l -delete
