#!/usr/bin/env bash
# Runs after the workspace is mounted. Everything that does not depend on the
# workspace (TinyTeX, Codex, Claude Code) is installed in the Dockerfile.
set -euo pipefail

VENV_DIR="${PWD}/.venv"

python3 -m venv "${VENV_DIR}"
. "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# Configure Codex
mkdir -p "$HOME/.codex"

cat > "$HOME/.codex/config.toml" <<'TOML'
sandbox_mode = "danger-full-access"
approval_policy = "on-request"
approvals_reviewer = "auto_review"
TOML

echo "Setup complete. Authenticate the agent CLI you want to use (codex or claude)."
