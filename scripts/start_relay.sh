#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

if [[ ! -x .venv/bin/python ]]; then
  echo "ERROR: .venv is missing. Run ./scripts/setup_mac.sh first." >&2
  exit 1
fi

if ! lsof -nP -iTCP:8766 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "ERROR: Mac 127.0.0.1:8766 is not listening." >&2
  echo "Start the VS Code/SSH local forward before the relay." >&2
  exit 1
fi

exec .venv/bin/python mac_phone_relay.py "$@"

