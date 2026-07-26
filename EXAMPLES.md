# Stomarchy Examples

Practical ways to keep your Omarchy setup personal, portable, and easy to update.

## Basic workflow

### Save your first tweak

Start with an unchanged Omarchy config and append your customization at the end of the file. For example:

```bash
$EDITOR ~/.config/hypr/bindings.lua
```

Add a complete, standalone Lua block:

```lua
hl.bind({ mods = { "SUPER", "SHIFT" }, key = "B" }, function()
  hl.spawn("zen-browser", "--private-window")
end)
```

Preview what Stomarchy will save, then add it:

```bash
stomarchy add --dry-run ~/.config/hypr/bindings.lua
stomarchy add ~/.config/hypr/bindings.lua
```

Your tweak now lives at:

```text
~/.config/stomarchy/.config/hypr/bindings.lua
```

The live Omarchy config is restored to its original content and finishes with:

```lua
-- BEGIN Stomarchy tweaks
dofile("/home/user/.config/stomarchy/.config/hypr/bindings.lua")
-- END Stomarchy tweaks
```

### Keep customizing

After the first `add`, make future changes in the tracked tweak:

```bash
$EDITOR ~/.config/stomarchy/.config/hypr/bindings.lua
stomarchy link ~/.config/hypr/bindings.lua
stomarchy status
```

This keeps Omarchy's file clean and makes your customization easy to commit, share, or remove.

### After an Omarchy update

Preview the new defaults with your tweaks attached:

```bash
stomarchy sync --dry-run
stomarchy sync
```

`sync` refreshes tracked configs from Omarchy and preserves their Stomarchy imports.

## Practical examples

### Example 1: Multiline Hyprland Lua

Stomarchy preserves the exact content you append, including multiline blocks:

```lua
hl.bind({
  mods = { "SUPER", "SHIFT" },
  key = "RETURN",
}, function()
  hl.spawn("ghostty", "--working-directory", os.getenv("HOME"))
end)
```

Add the block at the end of an unchanged `~/.config/hypr/*.lua` file, then run:

```bash
stomarchy add ~/.config/hypr/bindings.lua
```

The appended code must work as a standalone Lua chunk. Stomarchy validates both the tweak and the assembled config before replacing anything.

### Example 2: Tracking several configs

```bash
# Add customizations you have appended to supported Omarchy files
stomarchy add ~/.config/hypr/bindings.lua
stomarchy add ~/.config/ghostty/config
stomarchy add ~/.config/kitty/kitty.conf
stomarchy add ~/.config/tmux/tmux.conf
stomarchy add ~/.config/foot/foot.ini
stomarchy add ~/.bashrc

# Track complete user-owned files
stomarchy add ~/.inputrc
stomarchy add ~/.config/uwsm/default

# Check everything at once
stomarchy status
```

Stomarchy supports a focused set of formats with reliable runtime imports. Other files are refused rather than handled with a risky best guess.

### Example 3: Bash functions and aliases

Append your additions to `~/.bashrc`:

```bash
my_project() {
  cd -- "$HOME/Projects/my project" || return
}

alias gs='git status --short'
```

Then save them:

```bash
stomarchy add --dry-run ~/.bashrc
stomarchy add ~/.bashrc
```

The tracked additions live at `~/.config/stomarchy/.bashrc`. Omarchy's Bash defaults remain in place and source your file at startup.

### Example 4: A complete `.inputrc`

`.inputrc` is your file, so Stomarchy tracks the whole thing:

```bash
printf 'set editing-mode vi\n' > ~/.inputrc
stomarchy add ~/.inputrc
```

Edit the tracked copy and apply it whenever you like:

```bash
$EDITOR ~/.config/stomarchy/.inputrc
stomarchy link ~/.inputrc
```

To stop tracking it:

```bash
stomarchy remove ~/.inputrc
```

The tracked copy is removed, but your live `~/.inputrc` stays untouched. `~/.config/uwsm/default` follows the same full-file workflow.

### Example 5: Customizing Foot

Append your preferred Foot settings:

```ini
[colors]
alpha=0.95
```

Then add them:

```bash
stomarchy add ~/.config/foot/foot.ini
```

Stomarchy keeps those settings in `~/.config/stomarchy/.config/foot/foot.ini` and loads them through Foot's native include support.

### Example 6: Using Git

```bash
cd ~/.config/stomarchy
git init
git add .
git commit -m "Add my Omarchy tweaks"

git remote add origin git@github.com:username/my-omarchy-config.git
git push -u origin main
```

Only your customizations go into the repository. Omarchy's defaults stay with Omarchy.

### Example 7: Setting up a new machine

After installing Omarchy and Stomarchy:

```bash
git clone git@github.com:username/my-omarchy-config.git \
  "${XDG_CONFIG_HOME:-$HOME/.config}/stomarchy"

stomarchy link --dry-run
stomarchy link
stomarchy status
```

If a complete user-owned file already differs on the new machine, Stomarchy leaves it alone. Review the difference first, then merge it or use `--force` to save a recovery snapshot before replacement.

### Example 8: Linking checked-out tweaks

Apply every tracked tweak:

```bash
stomarchy link
```

Or apply just one, using either its live target or tracked path:

```bash
stomarchy link ~/.config/hypr/bindings.lua
stomarchy link ~/.config/stomarchy/.config/hypr/bindings.lua
stomarchy link ~/.config/stomarchy/.bashrc
```

`link` starts from the current Omarchy original and adds the right import. It never tries to rediscover tweaks from an edited live file.

### Example 9: Checking status

```bash
stomarchy status
```

Healthy tweaks are shown as `linked`. When something needs attention, the status explains the next step:

- `tweak-changed`: run `stomarchy link`
- `upstream-changed`: run `stomarchy sync`
- `drift`: review the live file before replacing it
- `unlinked`: run `stomarchy link`

For scripts and automated checks:

```bash
stomarchy status --porcelain
stomarchy status --check
```

### Example 10: Recovering from local drift

If a managed live file was edited directly, Stomarchy refuses to overwrite it:

```bash
stomarchy status
# The target is reported as drift
```

Move any changes you want to keep into the tracked tweak. If you have reviewed the file and want Stomarchy to replace it:

```bash
stomarchy link --force ~/.config/hypr/bindings.lua
```

Before replacing the target, Stomarchy prints the location of a timestamped recovery snapshot.

### Example 11: Removing a tweak

```bash
stomarchy remove ~/.config/hypr/bindings.lua
```

For an imported config, `remove` restores the current Omarchy original and deletes the tracked tweak. For a full-file config such as `.inputrc`, it deletes only the tracked copy.

### Example 12: Returning to Omarchy defaults

```bash
stomarchy wipe
```

`wipe` removes Stomarchy imports from tracked configs without deleting your tweaks. Full-file targets stay untouched, so you can return later with:

```bash
stomarchy link
```

## Advanced usage

### Refreshing the complete Omarchy config mirror

Normal `sync` and `wipe` commands affect only tracked files. To intentionally operate on the complete Omarchy configuration mirror:

```bash
stomarchy sync --all --force
stomarchy wipe --all --force
```

These broad operations create recovery snapshots first.

### Pointing to an Omarchy checkout

Most installed sessions tell Stomarchy where Omarchy lives automatically. For development or a source checkout, set:

```bash
export STOMARCHY_OMARCHY_ROOT=~/Projects/omarchy
```

## Tips and best practices

1. **Preview first**: Use `--dry-run` before your first `add`, after updates, and whenever you are unsure.
2. **Append only once**: After `add`, edit the tracked tweak and use `link`.
3. **Use Git**: Keep `~/.config/stomarchy/` under version control.
4. **Track selectively**: Save the customizations that make the setup yours.
5. **Sync after updates**: Bring in Omarchy's current defaults with `stomarchy sync`.
6. **Check status**: Let `stomarchy status` point you toward the right command.
7. **Treat `--force` as recovery-aware**: Review conflicts before asking Stomarchy to replace them.

## Troubleshooting

### The file is not supported

Run `stomarchy help` to see the supported adapters. Stomarchy only tracks files it can safely compose or restore.

### `add` says the change is not append-only

The live file must begin with the exact Omarchy original, with your customization added only at the end. Restore any changed or deleted original lines, then try the dry run again.

### A tweak is not taking effect

Check its health and relink it:

```bash
stomarchy status
stomarchy link /path/to/config
```

For Lua, make sure the tracked tweak is a complete standalone chunk.

### `link` or `sync` reports drift

The live target changed outside Stomarchy. Review it and move anything worth keeping into the tracked tweak. Use `--force` only when you intentionally want the managed version to replace it.
