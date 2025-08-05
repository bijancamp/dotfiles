# Dotfiles

My personal configuration files, managed with [chezmoi](https://www.chezmoi.io/).

## Key Chezmoi Variables

The following variables are used in generating appropriate configurations for different environments and contexts:
- **Host type (`.host.type`)**: `machine` (physical/VM) or `container` (dev container)
- **Host purpose (`.host.purpose`)**: `personal` or `work`
- **Operating system (`.chezmoi.os`)**: Windows-specific settings when applicable
- **Hostname (`.chezmoi.hostname`)**: Special handling for specific machines (e.g., personal desktop with Git signing keys)

## Dev Container Integration

### VS Code Settings

I use the following settings provided by the [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers):

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
- This repository is cloned to the default chezmoi source path within the container
- The custom installation script is executed after the repo is cloned

### Installation Scripts

#### install-devcontainer.sh

Automates the initial setup of chezmoi and dotfiles within dev containers.

**What it does**:
- Installs chezmoi
- Generates initial chezmoi configuration for containers
- Applies essential dotfiles
- Copies the script and `use.sh` (as `use`) to `~/.local/bin` for easy access

**Usage**: This script is automatically executed by VS Code when creating dev containers (via the `dotfiles.installCommand` setting). To execute manually, run `install-devcontainer.sh` within the container.

#### use.sh

Configures chezmoi for either personal or work use and reapplies dotfiles.

**What it does**:
- Prompts for container purpose (personal/work) or accepts command-line argument
- Sets the custom chezmoi `host.purpose` variable accordingly
- Regenerates dotfiles using the updated purpose

**Usage**:
```bash
# Interactive mode (will prompt for choice)
use

# Direct mode
use personal
use work
```

The script is automatically copied to `~/.local/bin/use` during dev container setup (via `install-devcontainer.sh`) for easy access.
