# Stomarchy Examples

This document provides practical examples of using Stomarchy to manage your Omarchy configurations.

## Basic Workflow

### Initial Setup

After installing both Omarchy and Stomarchy:

```bash
# 1. Make your customizations to Omarchy configs
# For example, edit ~/.config/omarchy/hypr/hyprland.conf

# 2. Backup your customizations
stomarchy backup

# This creates a timestamped backup and tracks it as "latest"
```

### After Omarchy Update

When Omarchy releases a new version:

```bash
# 1. Check what changed in the new version
stomarchy sync

# This will show you the diff between your current configs and the new defaults

# 2. Update Omarchy via your package manager
sudo pacman -S omarchy  # or yay -S omarchy-git

# 3. Restore your customizations
stomarchy restore

# This will append your custom configs via source directives
```

## Practical Examples

### Example 1: Customizing Hyprland Keybindings

Original Omarchy config (`~/.config/omarchy/hypr/hyprland.conf`):
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty
```

Your workflow:
```bash
# 1. Edit the config to add your keybindings
nano ~/.config/omarchy/hypr/hyprland.conf

# Add your custom bindings:
bind = SUPER, B, exec, firefox
bind = SUPER SHIFT, S, exec, grim

# 2. Backup your changes
stomarchy backup
```

After `stomarchy restore`, your config becomes:
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty

# Stomarchy customizations
source = ~/.config/stomarchy/custom/hypr/hyprland.conf
```

And `~/.config/stomarchy/custom/hypr/hyprland.conf` contains:
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty
bind = SUPER, B, exec, firefox
bind = SUPER SHIFT, S, exec, grim
```

### Example 2: Managing Multiple Backups

```bash
# Before making experimental changes
stomarchy backup
# Creates: ~/.config/stomarchy/backups/20250110_140000

# Make some changes...
# Try them out...

# Make another backup after tweaking
stomarchy backup
# Creates: ~/.config/stomarchy/backups/20250110_150000

# List your backups
ls ~/.config/stomarchy/backups/
# Output:
# 20250110_140000/
# 20250110_150000/
# latest -> 20250110_150000

# Restore from a specific backup
stomarchy restore 20250110_140000

# Or restore the latest
stomarchy restore
```

### Example 3: Checking Status

```bash
stomarchy status

# Output shows:
# - Omarchy installation location
# - Number and location of backups
# - Currently tracked Omarchy version
# - Number of custom configurations
```

### Example 4: Fresh Install Workflow

On a new machine or after fresh install:

```bash
# 1. Install Omarchy
sudo pacman -S omarchy

# 2. Install Stomarchy
sudo pacman -S stomarchy

# 3. (Optional) Copy your backup from another machine
# rsync -av old-machine:~/.config/stomarchy/backups/ ~/.config/stomarchy/backups/

# 4. Restore your customizations
stomarchy restore

# Your custom configs are now integrated!
```

## Advanced Usage

### Selective Restoration

If you want to restore only specific configs:

```bash
# 1. List files in a backup
find ~/.config/stomarchy/backups/latest -type f

# 2. Manually copy specific files
cp ~/.config/stomarchy/backups/latest/hypr/hyprland.conf \
   ~/.config/stomarchy/custom/hypr/hyprland.conf

# 3. Manually add source directive to Omarchy config
echo "" >> ~/.config/omarchy/hypr/hyprland.conf
echo "# Stomarchy customizations" >> ~/.config/omarchy/hypr/hyprland.conf
echo "source = ~/.config/stomarchy/custom/hypr/hyprland.conf" >> ~/.config/omarchy/hypr/hyprland.conf
```

### Version Tracking

Stomarchy tracks which Omarchy version it last synced with:

```bash
# Check tracked version
cat ~/.config/stomarchy/omarchy_version

# When you run sync, it compares this with the latest release
stomarchy sync

# This helps you see what changed between versions
```

## Tips and Best Practices

1. **Backup Often**: Run `stomarchy backup` before making significant changes
2. **Use Sync**: Run `stomarchy sync` periodically to stay aware of Omarchy updates
3. **Keep Backups Clean**: Old backups can be safely deleted from `~/.config/stomarchy/backups/`
4. **Check Status**: Use `stomarchy status` to verify your setup
5. **Test Restores**: After restore, verify your configs work as expected

## Troubleshooting

### "Omarchy directory not found"
- Ensure Omarchy is installed: `pacman -Q omarchy`
- Check the default location: `ls ~/.config/omarchy`

### "Backup not found"
- List available backups: `ls ~/.config/stomarchy/backups/`
- Use specific backup name: `stomarchy restore 20250110_140000`

### Custom configs not working
- Verify source directive was added: `grep -r "stomarchy" ~/.config/omarchy/`
- Check custom file exists: `ls ~/.config/stomarchy/custom/`
- Ensure the application supports `source` directives

### Restore not idempotent
- Stomarchy checks if source directives already exist before adding them
- Running restore multiple times is safe and won't duplicate directives
