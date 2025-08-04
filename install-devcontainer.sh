#!/bin/sh
# Script to install chezmoi and apply initial dotfiles in a devcontainer
# environment. Also copies utility scripts to ~/.local/bin for easy access.
# Assumes chezmoi-compatible dotfiles repo exists in default chezmoi source path
# (~/.local/share/chezmoi).
#
# Usage: ./devcontainer-install.sh

set -eu

echo "[dotfiles] Starting devcontainer-install.sh..."

# Install chezmoi
if ! chezmoi="$(command -v chezmoi)"; then
	bin_dir="$HOME/.local/bin"
	chezmoi="$bin_dir/chezmoi"

    echo "[dotfiles] Installing chezmoi into \$HOME/.local/bin..."

	if command -v curl >/dev/null; then
		chezmoi_install_script="$(curl -fsSL get.chezmoi.io)"
	elif command -v wget >/dev/null; then
		chezmoi_install_script="$(wget -qO- get.chezmoi.io)"
	else
		echo "To install chezmoi, you must have curl or wget installed." >&2
		exit 1
	fi

	sh -c "${chezmoi_install_script}" -- -b "${bin_dir}"
    echo "[dotfiles] chezmoi installed successfully."

	unset bin_dir chezmoi chezmoi_install_script
fi

# Helper function to run chezmoi at the installed location
# in case it's not in PATH yet
run_chezmoi() {
    "$HOME/.local/bin/chezmoi" "$@"
}

echo "[dotfiles] Generating chezmoi config file..."
run_chezmoi init --force --promptChoice "Host type=container" --promptString "Host purpose=unknown"
echo "[dotfiles] chezmoi config file generated."

# Applies a specific dotfile using chezmoi and reports status
# Parameters:
#   $1 - The full path to the dotfile to apply
apply_dotfile() {
    filename="$1"

    echo "[dotfiles] Applying '$filename'..."

    if run_chezmoi apply --force "$filename"; then
        echo "[dotfiles] Successfully applied '$filename'."
    else
        echo "[dotfiles] Warning: Failed to apply '$filename' (file may not exist in chezmoi source)." >&2
        # Don't exit - continue with other dotfiles
        return 0
    fi
}

# Apply essential dotfiles that are needed immediately in the devcontainer
echo "[dotfiles] Applying initial dotfiles with chezmoi..."
apply_dotfile "$HOME/.bash_profile"
apply_dotfile "$HOME/.bashrc"
echo "[dotfiles] Done applying initial dotfiles."

# Copy utility scripts to make them available in PATH
echo "[dotfiles] Copying scripts to \$HOME/.local/bin..."

# Copy this installation script itself to ~/.local/bin for future use
SCRIPT_NAME="${0##*/}"  # POSIX-compliant basename alternative
cp "$0" "$HOME/.local/bin/$SCRIPT_NAME"
chmod +x "$HOME/.local/bin/$SCRIPT_NAME"
echo "[dotfiles] Copied $SCRIPT_NAME to \$HOME/.local/bin."

# Copy use.sh from chezmoi source directory
SOURCE_PATH="$(run_chezmoi source-path)"
if [ -f "$SOURCE_PATH/use.sh" ]; then
    cp "$SOURCE_PATH/use.sh" "$HOME/.local/bin/use"
    chmod +x "$HOME/.local/bin/use"
    echo "[dotfiles] Copied use.sh to \$HOME/.local/bin as 'use'."
else
    echo "[dotfiles] Warning: use.sh not found in chezmoi source directory ($SOURCE_PATH)." >&2
    echo "[dotfiles] Skipping use.sh installation." >&2
fi

echo "[dotfiles] Initial dotfiles setup complete."
echo "[dotfiles] "
echo "[dotfiles] Next steps:"
echo "[dotfiles] 1. Restart your shell or run 'source ~/.bashrc' to load new settings"
echo "[dotfiles] 2. Run the 'use' command to configure git"
