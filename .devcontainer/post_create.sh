#!/usr/bin/env bash
set -euo pipefail

VENV_DIR="${PWD}/.venv"

python3 -m venv "${VENV_DIR}"
. "${VENV_DIR}/bin/activate"
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# Install Codex if needed
if ! command -v codex >/dev/null 2>&1; then
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

# Configure Codex
mkdir -p "$HOME/.codex"

cat > "$HOME/.codex/config.toml" <<'EOF'
sandbox_mode = "danger-full-access"
approval_policy = "on-request"
approvals_reviewer = "auto_review"
EOF

echo "Codex setup complete."