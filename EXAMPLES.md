# Stomarchy Examples

This document provides practical examples of using Stomarchy to manage your Omarchy configurations.

## Basic Workflow

### Initial Setup

After installing both Omarchy and Stomarchy:

```bash
# 1. Make your customizations to Omarchy configs
# For example, edit ~/.config/hypr/hyprland.conf

# 2. Track your runtime-representable changes with stomarchy.
# This also restores the target from Omarchy and adds the import block.
stomarchy add ~/.config/hypr/hyprland.conf

# 3. (Recommended) Version control your stomarchy directory
cd ~/.config/stomarchy
git init
git add .
git commit -m "Initial customizations"
```

### After Omarchy Update

When Omarchy ships changed defaults:

```bash
# 1. Update Omarchy via your package manager
sudo pacman -S omarchy  # or yay -S omarchy-git

# 2. Copy current Omarchy defaults into ~/.config
stomarchy sync

# This replaces Omarchy-managed config files and reattaches tracked imports
```

## Practical Examples

### Example 1: Customizing Hyprland Keybindings

Original Omarchy config (`~/.config/hypr/hyprland.conf`):
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty
```

Your workflow:
```bash
# 1. Edit the config to add your keybindings
nano ~/.config/hypr/hyprland.conf

# Add your custom bindings:
bind = SUPER, B, exec, firefox
bind = SUPER SHIFT, S, exec, grim

# 2. Track your changes with stomarchy.
# This also restores the original and adds the source directive.
stomarchy add ~/.config/hypr/hyprland.conf
```

The tracked snippet contains only your new runtime lines:

```conf
bind = SUPER, B, exec, firefox
bind = SUPER SHIFT, S, exec, grim
```

After `stomarchy add`, your Omarchy config becomes the Omarchy original plus an import block:
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty

# BEGIN Stomarchy customizations
source = /home/user/.config/stomarchy/.config/hypr/hyprland.conf
# END Stomarchy customizations
```

When you replace an existing Hyprland binding, Stomarchy adds an `unbind` line before your replacement in the snippet.

### Example 2: Hyprland Lua Configs

```bash
# Edit a next-generation Hyprland Lua config
nano ~/.config/hypr/hyprland.lua

# Track top-level runtime changes
stomarchy add ~/.config/hypr/hyprland.lua
```

The updated config uses `dofile()`:

```lua
-- BEGIN Stomarchy customizations
dofile("/home/user/.config/stomarchy/.config/hypr/hyprland.lua")
-- END Stomarchy customizations
```

If you replace `hl.bind("KEYS", ...)`, the snippet includes `hl.unbind("KEYS")` before the replacement. Edits inside existing Lua tables/functions are skipped with a warning because they are not safe standalone snippets.

### Example 3: Tracking Multiple Files

```bash
# Track several config files
stomarchy add ~/.config/hypr/hyprland.conf
stomarchy add ~/.config/hypr/hyprland.lua
stomarchy add ~/.config/kitty/kitty.conf
stomarchy add ~/.config/ghostty/config

# Check what's being tracked
stomarchy status

# Wire all checked-out snippets into ~/.config
stomarchy link

# Stop tracking one file and restore Omarchy's default
stomarchy remove ~/.config/hypr/hyprland.conf
```

Waybar JSONC/CSS, Alacritty TOML, YAML, XML, desktop files, binaries, and files outside `~/.config` are intentionally unsupported until they have reliable runtime import behavior.

### Example 4: Using Git for Version Control

```bash
# Initialize git in your stomarchy directory
cd ~/.config/stomarchy
git init

# Add all tracked files
git add .

# Commit your changes
git commit -m "Add my Omarchy customizations"

# Push to a remote (backup your configs!)
git remote add origin git@github.com:username/my-omarchy-config.git
git push -u origin main
```

### Example 5: Fresh Install Workflow

On a new machine or after fresh install:

```bash
# 1. Install Omarchy
sudo pacman -S omarchy

# 2. Install Stomarchy
sudo pacman -S stomarchy

# 3. Clone your stomarchy config from git
git clone git@github.com:username/my-omarchy-config.git ~/.config/stomarchy

# 4. Wire checked-out snippets into Omarchy
stomarchy link

# Your custom configs are now integrated!
```

### Example 6: Linking Checked-Out Snippets

```bash
# After cloning ~/.config/stomarchy from git
stomarchy link

# Or link just one checked-out snippet by target path
stomarchy link ~/.config/hypr/bindings.conf

# You can also point directly at the checked-out tracked snippet
stomarchy link ~/.config/stomarchy/.config/hypr/bindings.conf
```

`link` restores each target from the current Omarchy base config and adds the import block for the checked-out snippet. It does not recalculate snippets from edited `~/.config` files.

### Example 7: Checking Status

```bash
stomarchy status

# Output shows:
# - Stomarchy directory location
# - Omarchy defaults location
# - List of all tracked files
```

### Example 8: Removing a Customization

```bash
# Remove a tracked snippet and restore the Omarchy base config
stomarchy remove ~/.config/hypr/bindings.conf
```

This deletes `~/.config/stomarchy/.config/hypr/bindings.conf`, backs up the current `~/.config/hypr/bindings.conf`, and replaces it with `~/.local/share/omarchy/config/hypr/bindings.conf`.

## Advanced Usage

### Syncing with Omarchy Updates

```bash
# Copy current Omarchy defaults into ~/.config
stomarchy sync

# This will:
# - Copy files from ~/.local/share/omarchy/config/ into ~/.config/
# - Back up changed target files
# - Reattach import blocks for tracked Stomarchy snippets
```

### Directory Structure

After tracking some files:

```
~/.config/stomarchy/
├── .config/
│   ├── hypr/
│   │   ├── hyprland.conf
│   │   └── hyprland.lua
│   └── kitty/
│       └── kitty.conf
```

## Tips and Best Practices

1. **Use Git**: Version control your `~/.config/stomarchy/` directory with git
2. **Use Sync**: Run `stomarchy sync` after Omarchy updates to get the current defaults
3. **Use Link After Clone**: Run `stomarchy link` after checking out your tracked snippets from git
4. **Track Selectively**: Only track files you've actually customized
5. **Check Status**: Use `stomarchy status` to see what's being tracked
6. **After Omarchy Update**: Run `stomarchy sync` after updating Omarchy
7. **Remove Cleanly**: Use `stomarchy remove <file>` to return a file to Omarchy defaults
8. **Watch warnings**: Deletion-only, reorder-only, and unsupported partial edits are reported but not replayed

## Troubleshooting

### "File not found"
- Ensure the file exists: `ls -la <filepath>`
- Use absolute paths or paths relative to current directory

### Custom configs not working
- Verify source directive was added: `grep -r "stomarchy" ~/.config/`
- Check tracked file exists: `stomarchy status`
- Ensure the application supports the import directive Stomarchy uses
- For Lua, remember Stomarchy uses `dofile()` with an absolute tracked snippet path

### Repeated add behavior
- Stomarchy restores the Omarchy original and writes a marked import block
- Running `stomarchy add <file>` multiple times is safe and won't duplicate the block
