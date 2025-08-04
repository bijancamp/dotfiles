#!/bin/sh
# Script to configure chezmoi to use either personal or work configuration by
# generating a chezmoi.toml configuration file with the appropriate settings.
#
# Usage: use [personal|work]
#   - If no argument is provided, the user will be prompted to choose
#   - 'personal' sets up personal configuration
#   - 'work' sets up work configuration
#
# Prerequisites:
#   - chezmoi is installed (either in PATH or at ~/.local/bin/chezmoi)
#   - .chezmoi.toml.tmpl exists in the default chezmoi source directory

set -eu

# Path to chezmoi binary if it's not in PATH
CHEZMOI_BINARY="$HOME/.local/bin/chezmoi"

# Helper function to run chezmoi with fallback to different locations.
# First tries chezmoi from PATH, then from the specified binary location.
run_chezmoi() {
    # Check if chezmoi is available in PATH
    if command -v chezmoi >/dev/null 2>&1; then
        chezmoi "$@"
    # If not in PATH, check if it exists at CHEZMOI_BINARY location
    elif [ -x "$CHEZMOI_BINARY" ]; then
        "$CHEZMOI_BINARY" "$@"
    else
        echo "Error: chezmoi not found in PATH or at $CHEZMOI_BINARY." >&2
        echo "Please install chezmoi or update the CHEZMOI_BINARY path." >&2
        exit 1
    fi
}

main() {
    purpose=""

    # Determine which purpose to use based on command line argument or user prompt
    if [ "$#" -gt 0 ]; then
        # Parse command line argument
        case "$1" in
            "personal")
                purpose="personal"
                ;;
            "work")
                purpose="work"
                ;;
            *)
                echo "Error: Unknown purpose '$1'. Use 'personal' or 'work'." >&2
                echo "Usage: $0 [personal|work]" >&2
                exit 1
                ;;
        esac
    else
        # Interactive mode: prompt user for purpose choice
        while [ -z "$purpose" ]; do
            echo "Choose your dotfiles configuration:"
            echo "  1) personal"
            echo "  2) work"
            printf "Enter your choice (1 or 2): "
            read choice

            case "$choice" in
                1)
                    purpose="personal"
                    ;;
                2)
                    purpose="work"
                    ;;
                *)
                    echo "Error: Invalid choice '$choice'. Please enter 1 or 2." >&2
                    # Continue the loop to ask again
                    ;;
            esac
        done
    fi

    # Generate chezmoi configuration for the given purpose
    echo "Configuring chezmoi for $purpose use..."
    run_chezmoi init --force --promptChoice "Host type=container" --promptString "Host purpose=$purpose"
    echo "Successfully configured chezmoi for $purpose use."
    echo "Configuration saved to: $HOME/.config/chezmoi/chezmoi.toml"

    SOURCE_PATH="$(run_chezmoi source-path)"

    # Create backup of original .gitconfig if it doesn't exist
    if [ -f "$HOME/.gitconfig" ] && [ ! -f "$HOME/.gitconfig.orig" ]; then
        cp "$HOME/.gitconfig" "$HOME/.gitconfig.orig"
        echo "Created backup of original .gitconfig at ~/.gitconfig.orig."
    fi

    # Manually apply .gitconfig by combining template output with the original config
    {
        echo "# WARNING: Any manual changes to this file will be lost the next time 'use' is run.";
        echo "# To preserve custom settings, add them to ~/.gitconfig.orig as well.";
        echo "";
        run_chezmoi execute-template --force < "$SOURCE_PATH/dot_gitconfig.tmpl";
        echo "";
        if [ -f "$HOME/.gitconfig.orig" ]; then
            cat "$HOME/.gitconfig.orig";
        fi
    } > "$HOME/.gitconfig"

    echo "Successfully applied $HOME/.gitconfig for $purpose use."
}

main "$@"
