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
#   - .chezmoi-container.toml.tmpl exists in the default chezmoi source directory

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
        # Interactive mode: prompt user for purpose choice with personal as default
        while [ -z "$purpose" ]; do
            echo "Choose your dotfiles configuration:"
            echo "  1) personal (default)"
            echo "  2) work"
            printf "Enter your choice (1 or 2, default is 1): "
            read choice

            # Set default to 1 if user just pressed Enter
            if [ -z "$choice" ]; then
                choice=1
            fi

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
    echo "Configuration saved to: \$HOME/.config/chezmoi/chezmoi.toml"

    # Apply the selected configuration
    run_chezmoi apply --force "$HOME/.gitconfig"
    echo "Successfully applied \$HOME/.gitconfig for $purpose use."
}

main "$@"
