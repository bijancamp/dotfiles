# Dotfiles

My personal configuration files, managed by [chezmoi](https://www.chezmoi.io/).

## Overview

This repository contains my personal configuration files. My setup uses chezmoi for cross-platform support. It includes custom scripts for setting up dotfiles in dev containers.

## Key Files

- **Chezmoi configuration**: `.chezmoi.toml.tmpl` defines the configuration template with prompts for host type (machine/container) and purpose (personal/work)
- **Installation script**: `install-devcontainer.sh` automates the setup of chezmoi and essential dotfiles in dev containers
- **Configuration utility**: `use.sh` allows switching between personal and work configurations within dev containers. Intended to be run after `install-devcontainer.sh`
- **dot_***: My dotfiles

## Chezmoi Variables

The following variables are used to generate appropriate configurations for different environments and contexts:
- **Host type (`.host.type`)**: `machine` (physical/VM) or `container` (dev container)
- **Host purpose (`.host.purpose`)**: `personal` or `work`
- **Operating system (`.chezmoi.os`)**: Windows-specific settings when applicable
- **Hostname (`.chezmoi.hostname`)**: Special handling for specific machines (e.g., personal desktop with Git signing keys)

## Dev Container Support

### VS Code Settings

This system is designed to work with VS Code dev containers via the following settings:

```json
{
    "dev.containers.copyGitConfig": false,
    "dotfiles.installCommand": "install-devcontainer.sh",
    "dotfiles.repository": "bijancamp/dotfiles",
    "dotfiles.targetPath": "~/.local/share/chezmoi"
}
```

These settings ensure that:
- The host's .gitconfig is not automatically copied into the container (we generate it within the container via a chezmoi template)
- This repository is cloned to the standard chezmoi source location within the container
- The custom installation script is executed after the repo is cloned

### Installation Scripts

#### install-devcontainer.sh

**Purpose**: Automates the setup of chezmoi and essential dotfiles in a dev container environment.

**What it does**:
- Installs chezmoi
- Generates initial chezmoi configuration for containers
- Applies essential dotfiles (.bash_profile, .bashrc)
- Copies the script and `use.sh` (as `use`) to `~/.local/bin` for easy access

**Usage**: This script is automatically executed by VS Code when creating dev containers (configured via the `dotfiles.installCommand` setting). To execute manually, run `install-devcontainer.sh` in the container.

#### use.sh

**Purpose**: To complete dotfiles setup in a dev container by setting the custom chezmoi `host.purpose` data variable to either "personal" or "work" depending on the user's input. The script can also be rerun afterward to switch the purpose.

**What it does**:
- Prompts for configuration type (personal/work) or accepts command-line argument
- Regenerates chezmoi configuration with the selected purpose
- Applies .gitconfig and other relevant dotfiles for the chosen purpose

**Usage**:
```bash
# Interactive mode (will prompt for choice)
use

# Direct mode
use personal
use work
```

The script is automatically copied to `~/.local/bin/use` during dev container setup (via `install-devcontainer.sh`) for easy access.
