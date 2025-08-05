#!/bin/sh
# Script to install and initialize chezmoi in a devcontainer environment.
# Applies dotfiles for purpose 'unknown'. Installs `use` into '~/.local/bin' for
# easy access.
#
# Usage: ./install-devcontainer.sh

set -eu

echo "[dotfiles] Starting install-devcontainer.sh..."

INSTALL_DIR="$HOME/.local/bin"
CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"

# Install chezmoi
if ! chezmoi="$(command -v chezmoi)"; then
    echo "[dotfiles] Installing chezmoi into $INSTALL_DIR..."

	if command -v curl >/dev/null; then
		chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
	elif command -v wget >/dev/null; then
		chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
	else
		echo "[dotfiles] Error: To install chezmoi, you must have curl or wget installed." >&2
		exit 1
	fi

	sh -c "${chezmoi_install_script}" -- -b "${INSTALL_DIR}"
    echo "[dotfiles] chezmoi installed successfully."

	unset chezmoi_install_script
fi

# Initialize chezmoi
echo "[dotfiles] Initializing chezmoi and applying dotfiles (for purpose 'unknown')..."
"$INSTALL_DIR/chezmoi" init \
    --force \
    --apply \
    --prompt \
    --promptChoice="Host type=container" \
    --promptString="Host purpose=unknown" \
    --source="$CHEZMOI_SOURCE_DIR"
echo "[dotfiles] chezmoi initialized successfully."

# Install `use`
echo "[dotfiles] Installing \`use\` into '$INSTALL_DIR'..."
if [ -f "$CHEZMOI_SOURCE_DIR/use.sh" ]; then
    ln -s "$CHEZMOI_SOURCE_DIR/use.sh" "$INSTALL_DIR/use"
    echo "[dotfiles] \`use\` installed successfully."
else
    echo "[dotfiles] Warning: use.sh not found in chezmoi source directory ($CHEZMOI_SOURCE_DIR)." >&2
    echo "[dotfiles] Skipping \`use\` installation." >&2
fi

echo "[dotfiles] Initial dotfiles setup complete."
echo "[dotfiles] "
echo "[dotfiles] Next steps:"
echo "[dotfiles]   1. Restart your terminal or run \`source ~/.bashrc\` to load the applied version"
echo "[dotfiles]   2. Run the \`use\` command to finalize your dotfiles configuration"
