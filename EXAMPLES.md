# Stomarchy Examples

This document provides practical examples of using Stomarchy to manage your Omarchy configurations.

## Basic Workflow

### Initial Setup

After installing both Omarchy and Stomarchy:

```bash
# 1. Make your customizations to Omarchy configs
# For example, edit ~/.config/hypr/hyprland.conf

# 2. Track your customizations with stomarchy
stomarchy add ~/.config/hypr/hyprland.conf

# 3. Apply source directives to Omarchy configs
stomarchy apply

# 4. (Recommended) Version control your stomarchy directory
cd ~/.config/stomarchy
git init
git add .
git commit -m "Initial customizations"
```

### After Omarchy Update

When Omarchy releases a new version:

```bash
# 1. Check what changed in the new version
stomarchy sync

# This will show you the diff between your tracked files and the new defaults

# 2. Update Omarchy via your package manager
sudo pacman -S omarchy  # or yay -S omarchy-git

# 3. Reapply your customizations
stomarchy apply

# This will add source directives to the new Omarchy configs
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

# 2. Track your changes with stomarchy
stomarchy add ~/.config/hypr/hyprland.conf

# 3. Apply to add source directive
stomarchy apply
```

After `stomarchy apply`, your Omarchy config becomes:
```conf
bind = SUPER, Q, killactive
bind = SUPER, F, fullscreen
bind = SUPER, Return, exec, kitty

# Stomarchy customizations
source = ~/.config/stomarchy/.config/hypr/hyprland.conf
```

### Example 2: Tracking Multiple Files

```bash
# Track several config files
stomarchy add ~/.config/hypr/hyprland.conf
stomarchy add ~/.config/waybar/config
stomarchy add ~/.config/kitty/kitty.conf
stomarchy add ~/.bashrc

# Check what's being tracked
stomarchy status

# Apply all source directives at once
stomarchy apply
```

### Example 3: Using Git for Version Control

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

### Example 4: Fresh Install Workflow

On a new machine or after fresh install:

```bash
# 1. Install Omarchy
sudo pacman -S omarchy

# 2. Install Stomarchy
sudo pacman -S stomarchy

# 3. Clone your stomarchy config from git
git clone git@github.com:username/my-omarchy-config.git ~/.config/stomarchy

# 4. Apply your customizations
stomarchy apply

# Your custom configs are now integrated!
```

### Example 5: Checking Status

```bash
stomarchy status

# Output shows:
# - Stomarchy directory location
# - Currently tracked Omarchy version
# - List of all tracked files
```

## Advanced Usage

### Syncing with Omarchy Updates

```bash
# Check for Omarchy updates
stomarchy sync

# This will:
# - Fetch the latest Omarchy release
# - Compare with your tracked files
# - Show differences
# - Update the tracked version in .stomarchy-omarchy-version
```

### Directory Structure

After tracking some files:

```
~/.config/stomarchy/
├── .config/
│   ├── hypr/
│   │   └── hyprland.conf
│   ├── waybar/
│   │   └── config
│   └── kitty/
│       └── kitty.conf
├── .bashrc
└── .stomarchy-omarchy-version    # Internal: tracked Omarchy version

~/.cache/stomarchy/               # Downloaded Omarchy releases for diffing
```

## Tips and Best Practices

1. **Use Git**: Version control your `~/.config/stomarchy/` directory with git
2. **Use Sync**: Run `stomarchy sync` periodically to stay aware of Omarchy updates
3. **Track Selectively**: Only track files you've actually customized
4. **Check Status**: Use `stomarchy status` to see what's being tracked
5. **After Omarchy Update**: Always run `stomarchy apply` after updating Omarchy

## Troubleshooting

### "File not found"
- Ensure the file exists: `ls -la <filepath>`
- Use absolute paths or paths relative to current directory

### Custom configs not working
- Verify source directive was added: `grep -r "stomarchy" ~/.config/`
- Check tracked file exists: `stomarchy status`
- Ensure the application supports `source` directives

### Apply not idempotent
- Stomarchy checks if source directives already exist before adding them
- Running apply multiple times is safe and won't duplicate directives
