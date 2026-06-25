#!/bin/bash
# dotfiles tool script entry point
# Run nvim operations using dotfiles/nvim as the config directory,
# bypassing the Nix store read-only restriction.
#
# Usage: scripts.sh <command>
#   sync    Install/update/clean plugins, update lazy-lock.json
#   update  Update plugins to latest version, update lazy-lock.json
#   nvim    Start interactive nvim with dotfiles config (quick verify)
#   help    Show help

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
export XDG_CONFIG_HOME="$DOTFILES"

cmd="${1:-help}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  sync    Lazy sync  — install/update/clean plugins, update lazy-lock.json
  update  Lazy update — update plugins to latest version, update lazy-lock.json
  nvim    Start interactive nvim with dotfiles/nvim config (quick verify)
  help    Show this help

Examples:
  $(basename "$0") sync        # update lockfile after adding/removing plugins
  $(basename "$0") nvim        # quickly verify config changes
EOF
}

case "$cmd" in
  sync)
    echo ">> Lazy sync ($DOTFILES/nvim)..."
    nvim --headless +'Lazy! sync' +qa
    echo "✓ lazy-lock.json updated"
    echo "Check changes: git -C \"$DOTFILES\" diff nvim/lazy-lock.json"
    ;;
  update)
    echo ">> Lazy update ($DOTFILES/nvim)..."
    nvim --headless +'Lazy! update' +qa
    echo "✓ lazy-lock.json updated"
    echo "Check changes: git -C \"$DOTFILES\" diff nvim/lazy-lock.json"
    ;;
  nvim)
    echo ">> Starting nvim (config dir: $DOTFILES/nvim)..."
    exec nvim "${@:2}"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: $cmd"
    echo
    usage
    exit 1
    ;;
esac
