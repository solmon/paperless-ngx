#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/apply_migrations.sh [--no-input]
# This script attempts to apply Django migrations in a developer-friendly way.
# It will:
# - source `paperless.conf` if it exists to load environment overrides
# - activate .venv if present
# - export CA bundle env vars if the file exists at the configured path
# - prefer `uv run python manage.py migrate` if uv is available, otherwise call python directly

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# load simple KEY=VALUE lines from paperless.conf if present (do not source it directly)
if [ -f "$PROJECT_ROOT/paperless.conf" ]; then
  # Read each non-empty uncommented line that looks like KEY=VALUE and export it.
  # This avoids sourcing arbitrary content like arrays or JSON that exist in the file.
  while IFS= read -r line; do
    # strip leading/trailing whitespace
    trimmed="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    # skip empty lines and comments
    if [ -z "$trimmed" ] || [[ "$trimmed" == \#* ]]; then
      continue
    fi
    # only accept simple KEY=VALUE without spaces around '=' and without JSON/array characters
    if echo "$trimmed" | grep -qE '^[A-Z0-9_]+=[^\{\[\]\}].*$'; then
      key="$(echo "$trimmed" | cut -d= -f1)"
      value="$(echo "$trimmed" | cut -d= -f2- )"
      # remove possible surrounding quotes
      value="$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
      export "$key=$value"
    fi
  done < "$PROJECT_ROOT/paperless.conf"
fi

# default cert path used in upstream repo examples
ZSCALER_CERT="/home/solmon/github/questmind/zscaler_root.crt"
if [ -f "$ZSCALER_CERT" ]; then
  export PIP_CONFIG_FILE="$PROJECT_ROOT/.pip/pip.conf"
  export PIP_CERT="$ZSCALER_CERT"
  export SSL_CERT_FILE="$ZSCALER_CERT"
  export REQUESTS_CA_BUNDLE="$ZSCALER_CERT"
  export CURL_CA_BUNDLE="$ZSCALER_CERT"
fi

# use .venv python if available
if [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/.venv/bin/activate"
  PYTHON_BIN="$(which python3 || which python)"
else
  PYTHON_BIN="$(which python3 || which python)"
fi
export PAPERLESS_CONFIGURATION_PATH=/home/solmon/github/paperless-ngx/paperless.conf
# forward any args to migrate (e.g., --no-input)
MIGRATE_ARGS=("$@")
if command -v uv >/dev/null 2>&1; then
  echo "Running migrations with uv"
  # prefer uv so it syncs the environment as configured in pyproject
  uv run python src/manage.py migrate "${MIGRATE_ARGS[@]}"
else
  echo "Running migrations with local python"
  "$PYTHON_BIN" src/manage.py migrate "${MIGRATE_ARGS[@]}"
fi

echo "Migrations applied."
