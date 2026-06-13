# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). chezmoi renders
source files (many of them Go-templated) into the home directory of whatever machine
they're applied to, branching configuration by OS, host type, and host purpose. There
is no build/test/lint step — "running" the project means applying source state to the
target home directory with `chezmoi apply`.

## Source root is `home/`, not the repo root

`.chezmoiroot` contains `home`, so **all managed source state lives under `home/`.**
The repo root holds only meta files (`README.md`, `LICENSE`, `install-devcontainer.sh`,
`.vscode/`, `.specstory/`, `assets/`). When adding or editing a managed file, work
inside `home/`. The repo-root `.vscode/settings.json` only exists to give the `dot_*`
and `*.tmpl` source files correct syntax highlighting while editing.

## Filename conventions encode the target (source → target)

chezmoi derives each target path and its attributes from the source filename:
- `dot_bashrc` → `~/.bashrc` (the `dot_` prefix becomes a leading `.`)
- `*.tmpl` → rendered as a Go text/template, suffix stripped (`dot_gitconfig.tmpl` → `~/.gitconfig`)
- `empty_dot_hushlogin` → `~/.hushlogin`, kept even though zero-length (`empty_` permits empty files)
- `AppData/...` mirrors the Windows `%LOCALAPPDATA%`/`%APPDATA%` tree verbatim (Windows Terminal, VS Code, lazygit, TouchCursor)
- `.chezmoitemplates/` holds shared partials included via `{{ template "name" . }}` (used by the lazygit configs)

Renaming a source file relocates where it lands. Never rename without understanding the mapping.

## Templating model — the variables that drive everything

Every `.tmpl` branches on a small set of variables, set once at `chezmoi init` via the
`promptChoice`/`promptString` calls in `home/.chezmoi.toml.tmpl` and persisted to the
machine's local chezmoi config:
- `.chezmoi.os` — `windows` / `linux` / `darwin`
- `.chezmoi.hostname` — `DESKTOP-DIGAGVV` is the personal desktop; it is the only host that gets GPG commit signing and the WSL/native Ubuntu terminal profiles
- `.host.type` — `native` / `wsl` / `container`
- `.host.purpose` — `personal` / `work` / `unknown`
- `.company` — free text, used in the shell-prompt context segment

The same source tree therefore renders very differently per machine. `dot_gitconfig.tmpl`
is the clearest example: it selects entirely different `user`/`credential`/`includeIf`
blocks for Windows-personal vs Windows-work vs Linux-native/WSL vs dev-container, keyed
on these variables.

## Secrets — never inline them

Secret values are pulled at render time from the OS keyring via the `keyring` template
function (`keyring "<service>" "<user>"`):
- `keyring "vscode" "local-settings"` — appends private VS Code settings as trailing JSON (work machines)
- `keyring "git" ...` — work gitconfig `includeIf` path conditions
- `keyring "ado" ...` / `keyring "wt" ...` — Azure DevOps org name (used in the container init MCP setup) and the Windows Terminal Claude-agent starting directory

Set one with e.g. `chezmoi secret keyring set --service vscode --user local-settings`.
Separately, `home/.chezmoiexternal.toml` clones a private repo (`secretfiles`) into
`~/.secretfiles`, which holds the work gitconfig that templates `include`. Anything from
keyring or `.secretfiles` is intentionally out-of-band — do not commit it here.

## File inclusion is OS/host-gated

`home/.chezmoiignore.tmpl` excludes files per environment: Windows-only files (`AppData`,
`.claude/settings.json`, `.config/ccstatusline/...`, `.minttyrc`, `.gitconfig-windows`)
are ignored on non-Windows; lazygit config and `.hushlogin` are ignored off Linux; and
`.gitconfig-user-personal-signing` is ignored on every host except `DESKTOP-DIGAGVV`. If
a file you expect isn't applying, check this file first.

## Common commands

Run from anywhere — chezmoi resolves the source via its own config, with `home/` as the
implicit source root.

```bash
chezmoi diff                       # preview what apply would change
chezmoi apply -v                   # render source -> home dir (the "deploy")
chezmoi cat ~/.bashrc              # render a single target and print it (no write) — use to test template changes
chezmoi execute-template '{{ .host.purpose }}'   # eval arbitrary template logic / inspect a variable
chezmoi data                       # dump all template variables for this machine
chezmoi managed                    # list every path chezmoi controls
chezmoi init --apply --promptChoice="Host type=container" --promptChoice="Host purpose=unknown"   # re-init non-interactively
```

**Editing-workflow caveat:** editing a source file under `home/` does **not** change the
live config until you `chezmoi apply`. To check template output without applying, use
`chezmoi cat <target>` or `chezmoi execute-template`. The managed `.bashrc` provides
wrapper aliases that apply-and-reload in one step: `cha` (apply), `chd` (diff), `che`
(edit), `chia` (init --apply), `chu` (update); each re-sources `~/.bashrc` afterward.

## Shell environment (`home/dot_bashrc.tmpl`)

`~/.bash_profile` simply sources `~/.bashrc`. The bashrc is the largest template and the
primary place shell behavior is defined: a git-aware colored prompt whose context segment
is computed from `.host.purpose`/`.company`, a large family of `g*` git aliases (run `g?`
for a formatted, colorized listing), the chezmoi apply-and-reload wrapper functions, and
OS/purpose-gated sections — Windows work machines get `build`/`rebuild` MSBuild helpers
(`build_closest` walks up to the nearest buildable dir), and the `container` branch's
`chezmoi-init-for-containers` installs Claude Code MCP servers. It also sources
`~/.bash_aliases_additional`, which is **not** managed by chezmoi (machine-local additions).

## Dev containers

`install-devcontainer.sh` (wired via VS Code's `dotfiles.installCommand`) installs chezmoi
then runs `chezmoi init --apply` with `Host type=container` / `Host purpose=unknown`.
After the container starts, re-run `chezmoi init --apply` to set the real purpose; on a
`work` container that path also provisions the Claude Code MCP servers.
