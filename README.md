# stomarchy

Save and restore your Omarchy config without disrupting its opinionated design.

Stomarchy is a shell-script-based application similar to GNU Stow, designed specifically for managing [Omarchy](https://github.com/basecamp/omarchy) configuration files on Arch Linux. Unlike Stow which uses symlinks, Stomarchy appends your customizations to the default configs via import directives (like `source` in Hyprland configs), allowing you to maintain your tweaks while keeping Omarchy's opinionated design intact.

## Features

- 🔄 **Backup & Restore**: Save your Omarchy customizations and restore them seamlessly
- 📦 **Import-based**: Uses `source` directives instead of symlinks for cleaner integration
- 🔍 **Sync Tracking**: Monitor and sync with latest Omarchy releases
- 🎯 **Non-disruptive**: Preserves Omarchy's default configs while adding your tweaks
- 📊 **Status Dashboard**: View current state of configs, backups, and versions
- 🏗️ **Arch-ready**: Includes PKGBUILD for easy Arch Linux packaging

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

## Requirements

- **bash** - Shell interpreter
- **coreutils** - Basic file utilities
- **grep** - Text pattern matching
- **tar** - Archive extraction
- **curl** or **wget** - For downloading Omarchy releases (optional)
- **diffutils** - For showing config differences (optional)

## Usage

### Basic Commands

```bash
# Show help and available commands
stomarchy help

# Backup your current Omarchy customizations
stomarchy backup

# Restore customizations from latest backup
stomarchy restore

# Restore from specific backup
stomarchy restore 20250110_143022

# Check for Omarchy updates and see changes
stomarchy sync

# View current status
stomarchy status
```

### Typical Workflow

1. **Initial Setup**: After installing Omarchy and making your customizations:
   ```bash
   stomarchy backup
   ```

2. **After Omarchy Update**: When Omarchy releases a new version:
   ```bash
   stomarchy sync        # Check what changed
   # Update Omarchy through your package manager
   stomarchy restore     # Reapply your customizations
   ```

3. **Before Major Changes**: Before experimenting with configs:
   ```bash
   stomarchy backup
   # Make your changes
   # If you want to revert:
   stomarchy restore
   ```

## How It Works

Unlike GNU Stow which creates symlinks, Stomarchy:

1. **Backup**: Copies your Omarchy config files to timestamped backups
2. **Restore**: 
   - Stores your customizations in `~/.config/stomarchy/custom/`
   - Appends `source` directives to Omarchy's default config files
   - This allows Omarchy updates to modify defaults while preserving your tweaks
3. **Sync**: 
   - Fetches latest Omarchy release information
   - Downloads and compares configs
   - Shows you what changed in the defaults

### Example: Hyprland Config

After running `stomarchy restore`, your Hyprland config might look like:

```conf
# Original Omarchy defaults
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen

# Stomarchy customizations
source = /home/user/.config/stomarchy/custom/hypr/hyprland.conf
```

Your custom file contains only your tweaks, keeping everything organized and maintainable.

## Directory Structure

```
~/.config/stomarchy/
├── backups/
│   ├── 20250110_143022/    # Timestamped backup
│   ├── 20250110_150000/    # Another backup
│   └── latest -> 20250110_150000/  # Symlink to latest
├── custom/                  # Your customizations
│   └── hypr/
│       └── hyprland.conf
└── omarchy_version         # Tracked Omarchy version

~/.cache/stomarchy/         # Downloaded Omarchy releases
```

## Configuration

Stomarchy respects XDG Base Directory specifications:

- **Config**: `${XDG_CONFIG_HOME:-$HOME/.config}/stomarchy`
- **Cache**: `${XDG_CACHE_HOME:-$HOME/.cache}/stomarchy`
- **Omarchy**: `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Inspired by [GNU Stow](https://www.gnu.org/software/stow/)
- Designed for [Omarchy](https://github.com/basecamp/omarchy)
- Created by Brian Blakely
