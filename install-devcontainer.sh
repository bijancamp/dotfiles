#!/bin/sh
# Installs and initializes chezmoi in a devcontainer environment. Applies
# dotfiles for purpose 'unknown'.
#
# Also installs MCP servers for Claude Code.
#
# Usage: ./install-devcontainer.sh

set -eu

echo "[dotfiles] Starting install-devcontainer.sh..."

CHEZMOI_INSTALL_DIR="$HOME/.local/bin"
CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"

# Install chezmoi
if ! chezmoi="$(command -v chezmoi)"; then
    echo "[dotfiles] Installing chezmoi into $CHEZMOI_INSTALL_DIR..."

    if command -v curl >/dev/null; then
        chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
    elif command -v wget >/dev/null; then
        chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
    else
        echo "[dotfiles] Error: To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi

    sh -c "${chezmoi_install_script}" -- -b "${CHEZMOI_INSTALL_DIR}"
    echo "[dotfiles] chezmoi installed successfully."

    unset chezmoi_install_script
fi

# Initialize chezmoi
echo "[dotfiles] Initializing chezmoi and applying dotfiles (for purpose 'unknown')..."
"$CHEZMOI_INSTALL_DIR/chezmoi" init \
    --force \
    --apply \
    --prompt \
    --promptChoice="Host type=container" \
    --promptChoice="Host purpose=unknown" \
    --source="$CHEZMOI_SOURCE_DIR"
echo "[dotfiles] chezmoi initialized successfully."

echo "[dotfiles] Initial dotfiles setup complete."
echo "[dotfiles] "
echo "[dotfiles] Next steps:"
echo "[dotfiles]   1. Restart your terminal or run \`source ~/.bashrc\` to load the applied version"
echo "[dotfiles]   2. Run \`$CHEZMOI_INSTALL_DIR/chezmoi init --apply\` to finalize your dotfiles configuration"

# Install MCP servers for Claude Code
if command -v claude &> /dev/null; then
    claude mcp add playwright npx @playwright/mcp@latest --scope user
    claude mcp add --transport http context7 https://mcp.context7.com/mcp --scope user
    claude mcp add azure-devops -- npx -y @azure-devops/mcp "$(cat ~/.secretfiles/company-ado-org-name)" --scope user

    echo "[claude] MCP servers for Claude Code installed successfully."
fi
