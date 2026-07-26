# stomarchy

Save and restore your [Omarchy](https://omarchy.org/) config without disrupting
its opinionated design.

Stomarchy is a small, shell-based configuration manager inspired by
[GNU Stow](https://www.gnu.org/software/stow/). Instead of replacing Omarchy
files with symlinks, it keeps your personal tweaks separate and loads them on
top of Omarchy's defaults. You get a setup that still feels like Omarchy—just
with your favorite details preserved.

## Features

- 📦 **Import-based**: Loads your tweaks through each application's native
  import system
- ✂️ **Tweak-only**: Stores your custom additions instead of copying entire
  Omarchy configs
- 🔍 **Update-friendly**: Refreshes managed files from Omarchy's current local
  defaults
- 🎯 **Non-disruptive**: Keeps Omarchy's opinionated foundation intact
- 🛟 **Conflict-aware**: Stops before overwriting unexpected local changes
- 🏗️ **Arch-ready**: Includes everything needed to build an Arch Linux package
- 🔄 **Git-friendly**: Makes `~/.config/stomarchy/` easy to carry between
  machines

## Installation

### From source

```bash
git clone https://github.com/brianblakely/stomarchy.git
cd stomarchy
./install.sh
```

The installer uses `~/.local` for a regular user and `/usr/local` when run as
root.

### Using PKGBUILD

```bash
git clone https://github.com/brianblakely/stomarchy.git
cd stomarchy
makepkg -si
```

### Custom install prefix

```bash
PREFIX=/usr/local ./install.sh
```

Staged installs are supported with `DESTDIR`.

## Usage

### A typical workflow

Start with an untouched Omarchy config and append a self-contained
customization. For example, add a keybinding at the end of
`~/.config/hypr/bindings.lua`:

```lua
hl.bind({ mods = { "SUPER" }, key = "B" }, function()
  hl.spawn("zen-browser")
end)
```

Preview the change, then let Stomarchy track it:

```bash
stomarchy add --dry-run ~/.config/hypr/bindings.lua
stomarchy add ~/.config/hypr/bindings.lua
```

Stomarchy saves only the appended customization, restores Omarchy's original
file, and adds the appropriate import. From then on, edit the tracked tweak and
relink it:

```bash
$EDITOR ~/.config/stomarchy/.config/hypr/bindings.lua
stomarchy link ~/.config/hypr/bindings.lua
```

When Omarchy changes its defaults, bring those changes in without losing your
own:

```bash
stomarchy sync --dry-run
stomarchy sync
```

Your Omarchy configuration stays current, and your tweaks stay yours.

### Basic commands

```bash
# Show help and available commands
stomarchy help

# Preview and track a new tweak
stomarchy add --dry-run ~/.config/hypr/bindings.lua
stomarchy add ~/.config/hypr/bindings.lua

# Apply one tweak, or every checked-out tweak
stomarchy link ~/.config/hypr/bindings.lua
stomarchy link

# Check the health of tracked files
stomarchy status

# Refresh tracked files from current Omarchy defaults
stomarchy sync --dry-run
stomarchy sync

# Temporarily return tracked configs to Omarchy defaults
stomarchy wipe

# Stop tracking a file
stomarchy remove ~/.config/hypr/bindings.lua
```

See [EXAMPLES.md](EXAMPLES.md) for complete walkthroughs.

## How it works

Stomarchy keeps the Omarchy experience intact by separating your additions from
the files Omarchy owns:

1. **Add** compares a supported file with its Omarchy original, captures the
   exact customization appended to it, restores the original, and adds a native
   import for your tweak.
2. **Link** wires checked-out tweaks into their matching local configs without
   recalculating them.
3. **Sync** refreshes tracked configs from the current Omarchy originals and
   reattaches your imports.
4. **Wipe** removes imports from tracked configs while leaving every tweak ready
   to link again.
5. **Status** shows which tweaks are linked and flags anything that needs
   attention.
6. **Remove** restores an imported config to its Omarchy default before deleting
   the tracked tweak.

Stomarchy accepts appended customizations only when the original file is still
an exact match. It refuses in-place edits, deletions, and reordered content
because those changes cannot be replayed safely as a standalone tweak.

### Example: Hyprland Lua

After `stomarchy add`, the local config contains Omarchy's original content
followed by an import:

```lua
-- Original Omarchy config remains above

-- BEGIN Stomarchy tweaks
dofile("/home/user/.config/stomarchy/.config/hypr/bindings.lua")
-- END Stomarchy tweaks
```

The tracked file contains only your standalone Lua additions.

### Example: Bash

Append your functions, aliases, or environment setup to `~/.bashrc`, then run:

```bash
stomarchy add ~/.bashrc
```

Stomarchy restores Omarchy's Bash defaults and sources your tracked additions
from `~/.config/stomarchy/.bashrc`.

### Full-file tracking

Some files belong entirely to you rather than Omarchy. Stomarchy stores
supported full files as-is:

```bash
stomarchy add ~/.inputrc
stomarchy add ~/.config/uwsm/default
```

For these files, `add` stores the complete file, `link` copies it back, and
`remove` stops tracking it without changing the live file.

## Supported configs

Stomarchy supports files that can be composed safely at runtime:

| Config                     | How the tweak is loaded  |
| -------------------------- | ------------------------ |
| `~/.config/hypr/*.lua`     | Lua `dofile()`           |
| `~/.config/ghostty/config` | Ghostty `config-file`    |
| `~/.config/kitty/*.conf`   | Kitty `include`          |
| `~/.config/tmux/*.conf`    | tmux `source-file`       |
| `~/.config/foot/*.ini`     | Foot `include`           |
| `~/.bashrc`                | Bash `source`            |
| `~/.inputrc`               | Complete user-owned file |
| `~/.config/uwsm/default`   | Complete user-owned file |

Unregistered formats are left alone. That deliberate limit is what lets
Stomarchy preserve your setup without guessing how an application will interpret
a partial config.

## Git-friendly by design

Stomarchy mirrors tracked paths inside its own configuration directory:

```text
~/.config/stomarchy/
├── .config/
│   ├── hypr/
│   │   └── bindings.lua
│   ├── ghostty/
│   │   └── config
│   └── foot/
│       └── foot.ini
├── .bashrc
└── .inputrc
```

Turn that directory into a dotfiles repository:

```bash
cd ~/.config/stomarchy
git init
git add .
git commit -m "Track my Omarchy tweaks"
```

On another machine, clone it to the same location and run `stomarchy link`.

## Safety and recovery

Stomarchy checks for direct edits before replacing a managed file. If Omarchy
changed, `status` points you toward `sync`; if the assembled local file changed,
it reports drift and leaves the file alone.

When you intentionally want to replace a conflicting file, `--force` creates a
timestamped recovery snapshot first:

```bash
stomarchy link --force ~/.config/hypr/bindings.lua
```

Dry runs never create or modify files.

By default, `sync` and `wipe` affect tracked files only. Their `--all --force`
forms are available for deliberately refreshing or restoring the complete
Omarchy configuration mirror.

## Configuration

Stomarchy respects the XDG Base Directory specification:

- **Tracked tweaks**: `${XDG_CONFIG_HOME:-$HOME/.config}/stomarchy`
- **Machine-local state**: `${XDG_STATE_HOME:-$HOME/.local/state}/stomarchy`
- **Live configs**: `$HOME/.config`

Stomarchy finds Omarchy through `STOMARCHY_OMARCHY_ROOT`, `OMARCHY_PATH`, or the
standard system and user data locations. Most users do not need to configure
this themselves.

## Shell completion and man page

The installer and package include Bash completion and a `stomarchy(1)` man page.

## Contributing

Contributions are welcome. Please feel free to submit a pull request.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Credits

- Inspired by [GNU Stow](https://www.gnu.org/software/stow/)
- Designed for [Omarchy](https://github.com/basecamp/omarchy)
- Created by Brian Blakely
