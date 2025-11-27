# stomarchy

Save and restore your Omarchy config without disrupting its opinionated design.

Stomarchy is a shell-script-based application similar to GNU Stow, designed specifically for managing [Omarchy](https://github.com/basecamp/omarchy) configuration files on Arch Linux. Unlike Stow which uses symlinks, Stomarchy appends your customizations to the default configs via import directives (like `source` in Hyprland configs), allowing you to maintain your tweaks while keeping Omarchy's opinionated design intact.

## Features

- 📦 **Import-based**: Uses `source` directives instead of symlinks for cleaner integration
- 🔍 **Sync Tracking**: Monitor and sync with latest Omarchy releases
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

# Track a config file
stomarchy add ~/.config/hypr/hyprland.conf

# Apply source directives to Omarchy configs
stomarchy apply

# Check for Omarchy updates and see changes
stomarchy sync

# View current status
stomarchy status
```

### Typical Workflow

1. **Track your customizations**: After making your customizations:
   ```bash
   stomarchy add ~/.config/hypr/hyprland.conf
   ```

2. **Apply to Omarchy**: Add source directives to Omarchy configs:
   ```bash
   stomarchy apply
   ```

3. **After Omarchy Update**: When Omarchy releases a new version:
   ```bash
   stomarchy sync        # Check what changed
   # Update Omarchy through your package manager
   stomarchy apply       # Reapply your customizations
   ```

4. **Version control**: Use git to manage your customizations:
   ```bash
   cd ~/.config/stomarchy
   git init
   git add .
   git commit -m "Track my Omarchy customizations"
   ```

## How It Works

Unlike GNU Stow which creates symlinks, Stomarchy:

1. **Add**: Copies your config files to `~/.config/stomarchy/` preserving full directory structure
2. **Apply**: 
   - Appends `source` directives to Omarchy's default config files
   - This allows Omarchy updates to modify defaults while preserving your tweaks
3. **Sync**: 
   - Fetches latest Omarchy release information
   - Compares with your tracked files
   - Shows you what changed in the defaults

### Example: Hyprland Config

After running `stomarchy add` and `stomarchy apply`, your Hyprland config might look like:

```conf
# Original Omarchy defaults
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen

# Stomarchy customizations
source = /home/user/.config/stomarchy/.config/hypr/hyprland.conf
```

Your custom file is tracked in stomarchy with the full directory structure from home.

## Directory Structure

Stomarchy mirrors your home directory structure under `~/.config/stomarchy/`:

```
~/                              ~/.config/stomarchy/
├── .config/                    ├── .config/
│   └── hypr/                   │   └── hypr/
│       └── hyprland.conf       │       └── hyprland.conf
└── .bashrc                     ├── .bashrc
                                └── .stomarchy-omarchy-version
```

Internal stomarchy files are prefixed with `.stomarchy-` to avoid conflicts.

## Configuration

Stomarchy respects XDG Base Directory specifications:

- **Config**: `${XDG_CONFIG_HOME:-$HOME/.config}/stomarchy`
- **Cache**: `${XDG_CACHE_HOME:-$HOME/.cache}/stomarchy`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

- Inspired by [GNU Stow](https://www.gnu.org/software/stow/)
- Designed for [Omarchy](https://github.com/basecamp/omarchy)
- Created by Brian Blakely
