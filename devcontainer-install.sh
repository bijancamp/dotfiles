#!/bin/sh

set -e

echo "[dotfiles] Running devcontainerinstall.sh to set up dotfiles..."
echo "[dotfiles] Usage: $0 [personal|work]"

# Path to cloned dotfiles repo
DOTFILES_DIR="$HOME/dotfiles"

# Ensure the dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "[dotfiles] Error: Dotfiles directory '$DOTFILES_DIR' does not exist."
    exit 1
fi

echo "[dotfiles] Found dotfiles directory at '$DOTFILES_DIR'."

# Function to copy file and report status
copy_dotfile() {
    local src="$1"
    local dest="$2"
    local src_path="$DOTFILES_DIR/$src"
    local append_mode="$3"

    if [ ! -f "$src_path" ]; then
        echo "[dotfiles] Warning: Source file '$src' not found in dotfiles directory."
        return 1
    fi

    if [ "$append_mode" = "append" ]; then
        if [ -f "$dest" ]; then
            echo "" >> "$dest"  # add blank line separator
            echo "# Appended from $src" >> "$dest"
        fi

        cat "$src_path" >> "$dest"

        if [ $? -ne 0 ]; then
            echo "[dotfiles] Warning: Failed to append '$src' to '$dest'."
            return 1
        fi

        echo "[dotfiles] Successfully copied '$src' to '$dest'."
        return 0
    fi

    # Regular copy mode
    cp "$src_path" "$dest"

    if [ $? -ne 0 ]; then
        echo "[dotfiles] Warning: Failed to copy '$src' to '$dest'."
        return 1
    fi

    echo "[dotfiles] Successfully copied '$src' to '$dest'."
    return 0
}

# Copy basic dotfiles
echo "[dotfiles] Copying basic dotfiles..."
copy_dotfile "dot_bash_profile" "$HOME/.bash_profile"
copy_dotfile "dot_bashrc" "$HOME/.bashrc"
copy_dotfile "dot_gitconfig" "$HOME/.gitconfig" "append"

# Set up .gitconfig
echo "[dotfiles] Setting up .gitconfig..."

PROFILE=""

# Determine which profile to use
if [ "$#" -gt 0 ]; then
    case "$1" in
        "personal")
            PROFILE="personal"
            ;;
        "work")
            PROFILE="work"
            ;;
        *)
            echo "[dotfiles] Error: Invalid argument '$1'. Use 'personal' or 'work'."
            exit 1
            ;;
    esac
else
    # Prompt user for profile choice
    while [ -z "$PROFILE" ]; do
        echo "[dotfiles] Please choose a .gitconfig profile:"
        echo "  1) personal"
        echo "  2) work"
        printf "Enter your choice (1 or 2): "
        read -r choice
        case "$choice" in
            1)
                PROFILE="personal"
                ;;
            2)
                PROFILE="work"
                ;;
            *)
                echo "[dotfiles] Error: Invalid choice '$choice'. Please enter 1 or 2."
                ;;
        esac
    done
fi

GITCONFIG_FILE="dot_gitconfig-devcontainer-$PROFILE"

# Copy the selected gitconfig
copy_dotfile "$GITCONFIG_FILE" "$HOME/.gitconfig-devcontainer"

echo "[dotfiles] Done setting up dotfiles."
