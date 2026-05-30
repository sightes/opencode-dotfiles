#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME/.opencode-dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

LINKS=(
  ".config/opencode"
  ".config/fish"
  ".agents/skills"
  ".agents/.skill-lock.json"
  ".claude/CLAUDE.md"
  ".claude/skills"
)

echo "==> opencode-dotfiles bootstrap"
echo "    Repo:  $REPO_DIR"
echo "    Home:  $HOME_DIR"
echo "    Backups: $BACKUP_DIR"
echo ""

for relpath in "${LINKS[@]}"; do
  source="$REPO_DIR/$relpath"
  target="$HOME_DIR/$relpath"

  if [ ! -e "$source" ]; then
    echo "    SKIP $relpath (not in repo)"
    continue
  fi

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$relpath")"
    mv "$target" "$BACKUP_DIR/$relpath"
    echo "    BACKUP $relpath"
  fi

  mkdir -p "$(dirname "$target")"
  ln -sf "$source" "$target"
  echo "    LINK   $relpath"
done

echo ""
echo "==> Done. Backups saved to: $BACKUP_DIR"
echo "    To restore: mv $BACKUP_DIR/* ~/"
