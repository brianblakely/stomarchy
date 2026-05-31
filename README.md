# stomarchy

Save and restore your Omarchy config without disrupting its opinionated design.

Stomarchy is a shell-script-based application similar to GNU Stow, designed specifically for managing [Omarchy](https://omarchy.org/) configuration files. Unlike Stow which uses symlinks, Stomarchy stores diff-only runtime tweaks and imports them from restored Omarchy defaults, allowing you to maintain your tweaks while keeping Omarchy's opinionated design intact.

## Features

- 📦 **Import-based**: Uses source/import directives instead of symlinks for cleaner integration
- ✂️ **Diff-only**: Tracks only runtime-representable changes from edited configs
- 🔍 **Local Sync**: Refresh local config targets from Omarchy's current local defaults
- 🎯 **Non-disruptive**: Preserves Omarchy's default configs while adding your tweaks
- 🏗️ **Arch-ready**: Includes PKGBUILD for easy Arch Linux packaging
- 🔄 **Git-friendly**: Track your `~/.config/stomarchy/` directory with git

## Installation

### From Source

```bash
git clone https://github.com/brianblakely/stomarchy.git
cd stomarchy
./install.sh
```

### Using PKGBUILD (Arch Linux)

```bash
git clone https://github.com/brianblakely/stomarchy.git
cd stomarchy
makepkg -si
```

### Manual Installation

```bash
# Copy to system bin directory
sudo cp stomarchy /usr/bin/stomarchy
sudo chmod +x /usr/bin/stomarchy
```

## Usage

### Basic Commands

```bash
# Show help and available commands
stomarchy help

# Track diff-only changes and update the local file
stomarchy add --dry-run ~/.config/hypr/hyprland.conf
stomarchy add ~/.config/hypr/hyprland.conf
stomarchy add ~/.bashrc
stomarchy add ~/.inputrc

# Link checked-out tweaks into local files
stomarchy link

# Stop tracking a file and restore the Omarchy default
stomarchy remove ~/.config/hypr/hyprland.conf

# Preview or copy current Omarchy defaults into local files
stomarchy sync --dry-run
stomarchy sync

# Restore all local targets to Omarchy baselines
stomarchy wipe

# View current status
stomarchy status
```

### Typical Workflow

1. **Track and wire your tweaks.** After making your edits:

   ```bash
   stomarchy add --dry-run ~/.config/hypr/hyprland.conf
   stomarchy add ~/.config/hypr/hyprland.conf
   ```

2. **After an Omarchy update.** When Omarchy ships changed defaults:

   ```bash
   # Update Omarchy through your package manager
   stomarchy sync --dry-run
   stomarchy sync        # Copy current local defaults and reattach tweak imports
   ```

3. **Version control.** Use git to manage your tweaks:
   ```bash
   cd ~/.config/stomarchy
   git init
   git add .
   git commit -m "Track my Omarchy tweaks"
   ```

## How It Works

Unlike GNU Stow which creates symlinks, Stomarchy:

1. **Add**:
   - Looks up the untouched original in `~/.local/share/omarchy/config/`
   - Compares it with your edited target file
   - Stores only runtime-representable changes under `~/.config/stomarchy/`
   - With `--dry-run`, previews the tweak and leaves files untouched
   - Backs up the current target config
   - Restores the target from the Omarchy original
   - Appends a marked import block pointing at the tweak
2. **Sync**:
   - Copies every file from `~/.local/share/omarchy/config/` into the matching local target
   - With `--dry-run`, prints the diff that would be applied without writing files
   - Backs up changed target files before replacing them
   - Reattaches import blocks for Stomarchy tweaks
3. **Link**:
   - Scans checked-out tweaks in `~/.config/stomarchy/`
   - Restores each matching target from the Omarchy original
   - Appends the correct import block without recalculating tweaks
   - Accepts either a target config path or a tweak path for one-file linking
4. **Wipe**:
   - Copies current Omarchy originals into local targets without tweak imports
   - Leaves the tweak files in `~/.config/stomarchy/` intact
   - Returns local configs to the baseline Omarchy experience
5. **Status**:
   - Reports each tweak as linked or unlinked
   - Flags stale, no-op, unsupported, and missing-original tweaks
6. **Remove**:
   - Deletes the tweak for a specific file
   - Backs up the current target config
   - Restores the target from the Omarchy original without an import block

### Example: Hyprland Config

After running `stomarchy add`, your Hyprland config might look like:

```conf
# Original Omarchy defaults
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen

# BEGIN Stomarchy tweaks
source = /home/user/.config/stomarchy/.config/hypr/hyprland.conf
# END Stomarchy tweaks
```

The Stomarchy tweak contains only the added/replacement runtime lines, not a full copy of `hyprland.conf`.

### Example: Hyprland Lua Config

Hyprland Lua configs use `dofile()` so tweaks can stay in the same tracked location:

```lua
hl.set("general:gaps_in", 5)

-- BEGIN Stomarchy tweaks
dofile("/home/user/.config/stomarchy/.config/hypr/hyprland.lua")
-- END Stomarchy tweaks
```

Lua support is scoped to Hyprland configs under `~/.config/hypr/*.lua`. Stomarchy tracks top-level additive statements and normalizes replaced `hl.bind("KEYS", ...)` calls by emitting `hl.unbind("KEYS")` before the replacement.

### Example: Shell And Readline Dotfiles

`~/.bashrc` tweaks are imported with `source`, and `~/.inputrc` tweaks are imported with Readline's `$include` directive:

```bash
stomarchy add ~/.bashrc
stomarchy add ~/.inputrc
```

The tweaks live at `~/.config/stomarchy/.bashrc` and `~/.config/stomarchy/.inputrc`.

## Shell Completion And Man Page

The installer and PKGBUILD include bash completion and a `stomarchy(1)` man page.

## Directory Structure

Stomarchy mirrors `~/.config/` files under `~/.config/stomarchy/.config/` and stores supported home dotfiles at the root:

```
~/.config/                      ~/.config/stomarchy/
├── hypr/                       ├── .config/
│   ├── hyprland.conf           │   └── hypr/
│   └── hyprland.lua            │       ├── hyprland.conf
                                │       └── hyprland.lua
~/.bashrc                       ├── .bashrc
~/.inputrc                      └── .inputrc
```

Internal stomarchy files are prefixed with `.stomarchy-` to avoid conflicts.

## Configuration

Stomarchy respects XDG Base Directory specifications:

- **Config**: `${XDG_CONFIG_HOME:-$HOME/.config}/stomarchy`
- **Omarchy originals**: `${STOMARCHY_OMARCHY_CONFIG_DIR:-$HOME/.local/share/omarchy/config}`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Inspired by [GNU Stow](https://www.gnu.org/software/stow/)
- Designed for [Omarchy](https://github.com/basecamp/omarchy)
- Created by Brian Blakely
