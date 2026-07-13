# dotfiles

My macOS setup: zsh (oh-my-zsh), Neovim, tmux, Ghostty, asdf, Karabiner and
friends — managed with [GNU Stow](https://www.gnu.org/software/stow/) and a
single idempotent setup script.

## Install

```sh
git clone https://github.com/zaratan/dotfiles.git ~/dotfiles
cd ~/dotfiles
install/setup          # add --macos to also apply system defaults
```

On a blank Mac, `git clone` triggers the Command Line Tools install; `setup`
handles everything else: Homebrew, packages from the `Brewfile`, symlinks,
language runtimes via asdf, oh-my-zsh, tmux plugins and Claude Code (official
installer). Safe to re-run anytime — it only does what's missing.

Still manual afterwards: import SSH/GPG keys, sign in to apps.

### Migrating a machine from the old layout

> [!WARNING]
> Pulling this version on a machine installed with the old layout **breaks
> every existing symlink** (`~/.zshrc`, `~/bin`, `~/.config/nvim`, …): the
> files they point to no longer exist. The machine keeps running but any new
> shell starts unconfigured, and `install/setup` alone will refuse to fix it
> (Stow won't overwrite the dead links). Run `install/migrate-legacy` right
> after pulling — don't wait, and don't close your last working terminal
> before it succeeded.

If a machine was installed before the Stow migration (`*.symlink` files,
`script/bootstrap`), run this once after pulling:

```sh
cd ~/dotfiles && git pull && install/migrate-legacy
```

It materializes `~/.gitconfig.local`, removes the dead legacy symlinks (with
guards: only links pointing into the repo are touched), backs up any local
file that would collide with a package (as `*.pre-stow`), then runs
`install/setup`.

## Layout

```
Brewfile           # everything installed through Homebrew
config/            # one Stow package per topic
  zsh/ git/ ruby/ tmux/ nvim/ ghostty/ claude/ bin/ asdf/ karabiner/
install/
  setup            # the bootstrap script
  link             # optional convenience symlinks (~/iCloud, ~/Steam)
  macos-defaults.sh
  templates/       # *.example templates for local files
```

Each directory under `config/` mirrors `$HOME` and is linked with
`stow --dir=config --target=$HOME <package>`. Real file names, no naming
convention: `config/zsh/.zshrc` becomes `~/.zshrc`, `config/nvim/.config/nvim`
becomes `~/.config/nvim`. Remove a package's links with `stow -D <package>`.

## Local files (never committed)

Machine-specific and identity values live outside the repo, generated from
`install/templates/` on first setup:

| File                 | Purpose                              |
| -------------------- | ------------------------------------ |
| `~/.gitconfig.local` | git identity and signing key         |
| `~/.zshrc.local`     | `DEFAULT_USER`, `SSH_KEY_PATH`, etc. |
| `Brewfile.local`     | extra packages for this machine only |

## Forking

The repo is meant to be forkable without diverging: everything personal sits
in the local files above, so you can pull updates without conflicts.

1. Fork and clone, then run `install/setup` — it prompts for your identity.
2. Adjust `Brewfile` (or keep your extras in `Brewfile.local`).
3. Edit `config/asdf/.tool-versions` for your language versions.

## Maintenance

- `brew bundle dump --file=-` and compare with the `Brewfile` to spot drift.
- `asdf plugin update --all && asdf install` after bumping `.tool-versions`.
- Neovim plugins update through lazy.nvim (`:Lazy`); the lockfile stays local.
