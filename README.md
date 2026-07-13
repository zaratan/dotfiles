# dotfiles

These are my dotfiles: zsh (oh-my-zsh), Neovim, tmux, Ghostty, asdf and Karabiner.

Ever been bothered by spending a full day reinstalling a Mac by hand? There you go: one script installs everything, and [GNU Stow](https://www.gnu.org/software/stow/) keeps every config symlinked to this repo.

## Table of Contents

- [Why Stow?](#why-stow)
- [Installation](#installation)
  - [Migrating from the old layout](#migrating-from-the-old-layout)
- [What's inside](#whats-inside)
- [Local files](#local-files)
- [Forking](#forking)
- [Maintenance](#maintenance)

## Why Stow?

Dotfiles managers tend to be either hand-rolled bash (mine was 10 years old and showing it) or full frameworks like chezmoi that come with their own vocabulary and edit workflow. Stow does one thing: it symlinks a directory tree into `$HOME`.

This means `config/zsh/.zshrc` becomes `~/.zshrc`. There is no naming convention to remember and no templating layer between you and your files. Since the files in `$HOME` are symlinks to the repo, you can edit them from anywhere and commit from the repo, without any sync step. And when you want a package gone, `stow -D zsh` removes its links cleanly.

## Installation

```sh
git clone https://github.com/zaratan/dotfiles.git ~/dotfiles
cd ~/dotfiles
install/setup          # add --macos to also apply system defaults
```

On a blank Mac, `git clone` triggers the Command Line Tools install. `setup` handles everything else: Homebrew, packages from the `Brewfile`, symlinks, language runtimes via asdf, oh-my-zsh, tmux plugins and Claude Code (official installer). It is idempotent so you can re-run it anytime: it only does what's missing.

You still have to import your SSH/GPG keys and sign in to your apps yourself.

### Migrating from the old layout

> [!WARNING]
> Careful: pulling this version on a machine installed with the old layout (`*.symlink` files, `script/bootstrap`) breaks every existing symlink. `~/.zshrc`, `~/bin` or `~/.config/nvim` now point to files that no longer exist. The machine keeps running but any new shell starts unconfigured, and `install/setup` alone will refuse to fix it (Stow won't overwrite the dead links). Don't close your last working terminal before the migration succeeded.

Run this once after pulling:

```sh
cd ~/dotfiles && git pull && install/migrate-legacy
```

It turns `~/.gitconfig.local` back into a real file, removes the dead legacy symlinks (only links pointing into the repo are touched), backs up any local file that would collide with a package as `*.pre-stow`, then runs `install/setup`.

## What's inside

```
Brewfile           # everything installed through Homebrew
config/            # one Stow package per topic
  zsh/ git/ ruby/ tmux/ nvim/ ghostty/ claude/ bin/ asdf/ karabiner/
install/
  setup            # the bootstrap script
  migrate-legacy   # one-shot migration from the pre-Stow layout
  link             # optional convenience symlinks (~/iCloud, ~/Steam)
  macos-defaults.sh
  templates/       # *.example templates for local files
```

Each directory under `config/` mirrors `$HOME` and is linked with `stow --dir=config --target=$HOME <package>`.

## Local files

Machine-specific and identity values live outside the repo. `setup` generates them from `install/templates/` on first run:

| File                 | Purpose                              |
| -------------------- | ------------------------------------ |
| `~/.gitconfig.local` | git identity and signing key         |
| `~/.zshrc.local`     | `DEFAULT_USER`, `SSH_KEY_PATH`, etc. |
| `Brewfile.local`     | extra packages for this machine only |

## Forking

This repo is meant to be forked: everything personal sits in the local files above, so you can customize your fork and still pull my updates without conflicts.

1. Fork and clone, then run `install/setup`. It prompts for your identity.
2. Adjust the `Brewfile` (or keep your extras in `Brewfile.local`).
3. Edit `config/asdf/.tool-versions` for your language versions.

## Maintenance

- `brew bundle dump --file=-` and compare with the `Brewfile` to spot drift.
- `asdf plugin update --all && asdf install` after bumping `.tool-versions`.
- Neovim plugins update through lazy.nvim (`:Lazy`); the lockfile stays local on purpose.

## License

This repo is available as open source under the terms of the [MIT License](LICENSE.md).
