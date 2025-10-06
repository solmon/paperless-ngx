#!/usr/bin/env bash
set -euo pipefail

# Load .env if present so env vars (DB, SECRET_KEY, etc.) are available
if [ -f .env ]; then
  # shellcheck source=/dev/null
  source .env
fi

# Ensure we're running from repo root
cd "$(dirname "$0")/.." || true

exec python src/manage.py runserver 0.0.0.0:8000
