#!/bin/sh
set -eu

[ "$(uname -s)" = "Darwin" ] || { printf 'This uninstaller is for macOS.\n' >&2; exit 1; }

CODEX_API_HOME=${CODEX_API_HOME:-"$HOME/.codex-api"}
BIN_DIR=${CODEX_API_BIN_DIR:-"$HOME/.local/bin"}
BACKUP="$HOME/.codex-api-backup/uninstall-$(date '+%Y%m%d-%H%M%S')"

if [ -d "$CODEX_API_HOME" ]; then
  mkdir -p "$(dirname "$BACKUP")"
  mv "$CODEX_API_HOME" "$BACKUP"
  printf 'API-mode files moved to %s\n' "$BACKUP"
fi

rm -f "$BIN_DIR/codex-api"
security delete-generic-password -a "$(id -un)" -s codex-api-setup >/dev/null 2>&1 || true
printf 'Removed codex-api mode. The official Codex CLI and ~/.codex were not changed.\n'

