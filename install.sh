#!/bin/sh
set -eu

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'This installer is for macOS. Windows users should run install.ps1.\n' >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODEX_API_HOME=${CODEX_API_HOME:-"$HOME/.codex-api"}
BIN_DIR=${CODEX_API_BIN_DIR:-"$HOME/.local/bin"}
KEYCHAIN_SERVICE="codex-api-setup"
KEYCHAIN_ACCOUNT="$(id -un)"

prompt_required() {
  prompt_text=$1
  value=''
  while [ -z "$value" ]; do
    printf '%s' "$prompt_text" >&2
    IFS= read -r value
  done
  printf '%s' "$value"
}

toml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if ! command -v codex >/dev/null 2>&1; then
  printf 'Codex CLI is not installed. Installing it with the official OpenAI installer...\n'
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
  PATH="$HOME/.local/bin:$PATH"
  export PATH
fi

if ! command -v codex >/dev/null 2>&1; then
  printf 'Codex was installed but is not visible in this terminal. Restart the terminal and rerun this script.\n' >&2
  exit 1
fi

codex --version

BASE_URL=$(prompt_required 'API Base URL (must support the Responses API): ')
MODEL=$(prompt_required 'Model ID: ')
printf 'Reasoning effort [high]: '
IFS= read -r REASONING
REASONING=${REASONING:-high}
case "$REASONING" in
  minimal|low|medium|high|xhigh) ;;
  *) printf 'Invalid reasoning effort. Use minimal, low, medium, high, or xhigh.\n' >&2; exit 1 ;;
esac

printf 'API Key (stored in macOS Keychain): '
trap 'stty echo 2>/dev/null || true' EXIT HUP INT TERM
stty -echo
IFS= read -r API_KEY
stty echo
printf '\n'
[ -n "$API_KEY" ] || { printf 'API Key cannot be empty.\n' >&2; exit 1; }

if [ -d "$CODEX_API_HOME" ]; then
  BACKUP="$HOME/.codex-api-backup/$(date '+%Y%m%d-%H%M%S')"
  mkdir -p "$(dirname "$BACKUP")"
  cp -R "$CODEX_API_HOME" "$BACKUP"
  printf 'Existing API-mode configuration backed up to %s\n' "$BACKUP"
fi

mkdir -p "$CODEX_API_HOME" "$BIN_DIR"
chmod 700 "$CODEX_API_HOME" "$BIN_DIR"

BASE_URL_ESCAPED=$(toml_escape "$BASE_URL")
MODEL_ESCAPED=$(toml_escape "$MODEL")
cat > "$CODEX_API_HOME/config.toml" <<EOF
model_provider = "custom"
model = "$MODEL_ESCAPED"
model_reasoning_effort = "$REASONING"
sandbox_mode = "workspace-write"
approval_policy = "on-request"

[model_providers.custom]
name = "Custom OpenAI-compatible provider"
base_url = "$BASE_URL_ESCAPED"
env_key = "CODEX_API_KEY"
wire_api = "responses"
requires_openai_auth = false

[sandbox_workspace_write]
network_access = true
EOF

install -m 600 "$SCRIPT_DIR/AGENTS.md" "$CODEX_API_HOME/AGENTS.md"
security add-generic-password -U -a "$KEYCHAIN_ACCOUNT" -s "$KEYCHAIN_SERVICE" -w "$API_KEY" >/dev/null
unset API_KEY

cat > "$BIN_DIR/codex-api" <<'EOF'
#!/bin/sh
set -eu
export CODEX_HOME="${CODEX_API_HOME:-$HOME/.codex-api}"
export CODEX_API_KEY="$(security find-generic-password -a "$(id -un)" -s codex-api-setup -w)"
exec codex "$@"
EOF
chmod 700 "$BIN_DIR/codex-api"
chmod 600 "$CODEX_API_HOME/config.toml"

CODEX_HOME="$CODEX_API_HOME" codex features list >/dev/null
printf '\nSetup complete.\n'
printf 'Account mode: codex\n'
printf 'API mode:     codex-api\n'
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) printf 'Add %s to PATH, then restart your terminal.\n' "$BIN_DIR" ;;
esac
