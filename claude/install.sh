#!/usr/bin/env bash
#
# Symlink Claude Code user config files into ~/.claude/

set -e

CLAUDE_DIR="$HOME/.claude"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$CLAUDE_DIR"

link_claude_file() {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "${dst}.backup"
    echo "  backed up $dst -> ${dst}.backup"
  fi

  ln -s "$src" "$dst"
  echo "  linked $dst"
}

# Individual config files
for file in settings.json CLAUDE.md statusline-command.sh; do
  link_claude_file "$SOURCE_DIR/$file" "$CLAUDE_DIR/$file"
done

# Agents directory (symlink the whole dir so new agents are auto-tracked)
if [ -L "$CLAUDE_DIR/agents" ]; then
  rm "$CLAUDE_DIR/agents"
elif [ -d "$CLAUDE_DIR/agents" ]; then
  mv "$CLAUDE_DIR/agents" "$CLAUDE_DIR/agents.backup"
  echo "  backed up agents/ -> agents.backup/"
fi

ln -s "$SOURCE_DIR/agents" "$CLAUDE_DIR/agents"
echo "  linked agents/"
