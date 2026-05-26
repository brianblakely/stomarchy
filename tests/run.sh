#!/bin/bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="${ROOT_DIR}/stomarchy"
PASS_COUNT=0
FAIL_COUNT=0

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq "$expected" "$file" || fail "Expected ${file} to contain: ${expected}"
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    if grep -Fq "$unexpected" "$file"; then
        fail "Expected ${file} not to contain: ${unexpected}"
    fi
}

assert_file_exists() {
    local file="$1"

    [ -f "$file" ] || fail "Expected file to exist: $file"
}

assert_file_not_exists() {
    local file="$1"

    [ ! -e "$file" ] || fail "Expected file not to exist: $file"
}

assert_empty_file() {
    local file="$1"

    assert_file_exists "$file"
    [ ! -s "$file" ] || fail "Expected file to be empty: $file"
}

with_temp_home() {
    local name="$1"
    shift
    local tmp_dir

    tmp_dir=$(mktemp -d)

    if (
        export HOME="${tmp_dir}/home"
        export XDG_CONFIG_HOME="${HOME}/.config"
        export STOMARCHY_OMARCHY_CONFIG_DIR="${tmp_dir}/omarchy/config"
        mkdir -p "$XDG_CONFIG_HOME" "$STOMARCHY_OMARCHY_CONFIG_DIR"
        cd "$tmp_dir"
        "$@"
    ); then
        echo "ok - ${name}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "not ok - ${name}" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    rm -rf "$tmp_dir"
}

test_rejects_outside_config() {
    mkdir -p "${HOME}/Documents"
    printf 'x\n' > "${HOME}/Documents/file.conf"

    if "$SCRIPT" add "${HOME}/Documents/file.conf" > out.log 2> err.log; then
        fail "add succeeded for a file outside ~/.config"
    fi

    assert_file_contains err.log "File must be under config directory"
}

test_rejects_missing_original() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr"
    printf 'workspace = 1\n' > "${XDG_CONFIG_HOME}/hypr/missing.conf"

    if "$SCRIPT" add "${XDG_CONFIG_HOME}/hypr/missing.conf" > out.log 2> err.log; then
        fail "add succeeded without an Omarchy original"
    fi

    assert_file_contains err.log "Omarchy original not found"
}

test_hypr_conf_snippet() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, brave"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, firefox"
        echo "workspace = 1, monitor:DP-3"
    } > "${XDG_CONFIG_HOME}/hypr/bindings.conf"

    "$SCRIPT" add "${XDG_CONFIG_HOME}/hypr/bindings.conf" > out.log

    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    assert_file_contains "$snippet" "unbind = SUPER, B"
    assert_file_contains "$snippet" "bind = SUPER, B, exec, firefox"
    assert_file_contains "$snippet" "workspace = 1, monitor:DP-3"
}

test_hypr_lua_top_level_snippet() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    {
        echo 'local hl = require("hyprland")'
        echo 'hl.set("general:gaps_in", 5)'
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/hyprland.lua"

    {
        echo 'local hl = require("hyprland")'
        echo 'hl.set("general:gaps_in", 5)'
        echo 'hl.set("general:gaps_out", 12)'
    } > "${XDG_CONFIG_HOME}/hypr/hyprland.lua"

    "$SCRIPT" add "${XDG_CONFIG_HOME}/hypr/hyprland.lua" > out.log

    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/hyprland.lua"
    assert_file_contains "$snippet" 'hl.set("general:gaps_out", 12)'
}

test_hypr_lua_bind_replacement() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    echo 'hl.bind("SUPER, B", function() hl.spawn("brave") end)' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/hyprland.lua"
    echo 'hl.bind("SUPER, B", function() hl.spawn("firefox") end)' > "${XDG_CONFIG_HOME}/hypr/hyprland.lua"

    "$SCRIPT" add "${XDG_CONFIG_HOME}/hypr/hyprland.lua" > out.log

    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/hyprland.lua"
    assert_file_contains "$snippet" 'hl.unbind("SUPER, B")'
    assert_file_contains "$snippet" 'hl.bind("SUPER, B", function() hl.spawn("firefox") end)'
}

test_hypr_lua_partial_table_skip() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    {
        echo "hl.config({"
        echo "  general = {"
        echo "    gaps_in = 5,"
        echo "  },"
        echo "})"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/hyprland.lua"

    {
        echo "hl.config({"
        echo "  general = {"
        echo "    gaps_in = 4,"
        echo "  },"
        echo "})"
    } > "${XDG_CONFIG_HOME}/hypr/hyprland.lua"

    "$SCRIPT" add "${XDG_CONFIG_HOME}/hypr/hyprland.lua" > out.log

    assert_empty_file "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/hyprland.lua"
    assert_file_contains out.log "Skipped Lua edits"
}

test_unsupported_waybar_fails() {
    mkdir -p "${XDG_CONFIG_HOME}/waybar" "${STOMARCHY_OMARCHY_CONFIG_DIR}/waybar"

    echo '{"position": "top"}' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/waybar/config.jsonc"
    echo '{"position": "bottom"}' > "${XDG_CONFIG_HOME}/waybar/config.jsonc"

    if "$SCRIPT" add "${XDG_CONFIG_HOME}/waybar/config.jsonc" > out.log 2> err.log; then
        fail "add succeeded for unsupported Waybar JSONC"
    fi

    assert_file_contains err.log "Unsupported config format"
    assert_file_not_exists "${XDG_CONFIG_HOME}/stomarchy/.config/waybar/config.jsonc"
}

test_add_restores_original_and_is_idempotent() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, brave"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, firefox"
        echo "workspace = 1, monitor:DP-3"
    } > "${XDG_CONFIG_HOME}/hypr/bindings.conf"

    local target="${XDG_CONFIG_HOME}/hypr/bindings.conf"
    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"

    "$SCRIPT" add "$target" > add-one.log

    assert_file_contains "$target" "bind = SUPER, B, exec, brave"
    assert_file_contains "$target" "source = ${snippet}"
    assert_file_not_contains "$target" "workspace = 1, monitor:DP-3"
    assert_file_contains "$snippet" "workspace = 1, monitor:DP-3"

    compgen -G "${target}.stomarchy-backup.*" > /dev/null || fail "Expected add to create a backup"

    "$SCRIPT" add "$target" > add-two.log
    [ "$(grep -c "BEGIN Stomarchy customizations" "$target")" -eq 1 ] || fail "Expected one Stomarchy block after repeated add"
    assert_file_contains "$snippet" "workspace = 1, monitor:DP-3"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, zen-browser"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    "$SCRIPT" add "$target" > add-after-original-change.log
    assert_file_contains "$target" "bind = SUPER, B, exec, zen-browser"
    assert_file_contains "$snippet" "workspace = 1, monitor:DP-3"
    assert_file_not_contains "$snippet" "zen-browser"
}

test_lua_add_uses_tracked_snippet_path() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    echo 'hl.set("general:gaps_in", 5)' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/hyprland.lua"
    {
        echo 'hl.set("general:gaps_in", 5)'
        echo 'hl.set("general:gaps_out", 12)'
    } > "${XDG_CONFIG_HOME}/hypr/hyprland.lua"

    local target="${XDG_CONFIG_HOME}/hypr/hyprland.lua"
    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/hyprland.lua"

    "$SCRIPT" add "$target" > add.log

    assert_file_contains "$target" "dofile(\"${snippet}\")"
    assert_file_not_contains "$target" "_stomarchy"
}

test_link_checked_out_snippets() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty" "${XDG_CONFIG_HOME}/stomarchy/.config/hypr" "${XDG_CONFIG_HOME}/stomarchy/.config/ghostty" "${XDG_CONFIG_HOME}/ghostty"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, brave"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    echo "workspace = 1, monitor:DP-3" > "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    echo "font-size = 9" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty/config"
    echo "font-size = 11" > "${XDG_CONFIG_HOME}/stomarchy/.config/ghostty/config"
    echo "user-edited stale target" > "${XDG_CONFIG_HOME}/ghostty/config"

    "$SCRIPT" link > link.log

    local hypr_target="${XDG_CONFIG_HOME}/hypr/bindings.conf"
    local hypr_snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    local ghostty_target="${XDG_CONFIG_HOME}/ghostty/config"
    local ghostty_snippet="${XDG_CONFIG_HOME}/stomarchy/.config/ghostty/config"

    assert_file_contains "$hypr_target" "bind = SUPER, B, exec, brave"
    assert_file_contains "$hypr_target" "source = ${hypr_snippet}"
    assert_file_contains "$hypr_snippet" "workspace = 1, monitor:DP-3"
    assert_file_contains "$ghostty_target" "font-size = 9"
    assert_file_contains "$ghostty_target" "config-file = \"${ghostty_snippet}\""
    assert_file_contains "$ghostty_snippet" "font-size = 11"
    compgen -G "${ghostty_target}.stomarchy-backup.*" > /dev/null || fail "Expected link to back up stale target"
    assert_file_contains link.log "Linked 2 tracked snippet"
}

test_link_single_file() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty" "${XDG_CONFIG_HOME}/stomarchy/.config/hypr" "${XDG_CONFIG_HOME}/stomarchy/.config/ghostty"

    echo "bind = SUPER, Q, killactive" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"
    echo "workspace = 1" > "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    echo "font-size = 9" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty/config"
    echo "font-size = 11" > "${XDG_CONFIG_HOME}/stomarchy/.config/ghostty/config"

    "$SCRIPT" link "${XDG_CONFIG_HOME}/hypr/bindings.conf" > link.log

    assert_file_contains "${XDG_CONFIG_HOME}/hypr/bindings.conf" "source = ${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    assert_file_not_exists "${XDG_CONFIG_HOME}/ghostty/config"
}

test_link_single_tracked_file() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${XDG_CONFIG_HOME}/stomarchy/.config/hypr"

    echo "bind = SUPER, Q, killactive" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"
    echo "workspace = 1" > "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"

    "$SCRIPT" link "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf" > link.log

    assert_file_contains "${XDG_CONFIG_HOME}/hypr/bindings.conf" "source = ${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
}

test_link_ignores_git_checkout_files() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${XDG_CONFIG_HOME}/stomarchy/.config/hypr" "${XDG_CONFIG_HOME}/stomarchy/.git/objects"

    echo "bind = SUPER, Q, killactive" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"
    echo "workspace = 1" > "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    echo "ref: refs/heads/main" > "${XDG_CONFIG_HOME}/stomarchy/.git/HEAD"
    echo "[core]" > "${XDG_CONFIG_HOME}/stomarchy/.git/config"

    "$SCRIPT" link > link.log 2> err.log

    assert_file_contains "${XDG_CONFIG_HOME}/hypr/bindings.conf" "source = ${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    assert_file_contains link.log "Linked 1 tracked snippet"
    assert_file_not_contains err.log ".git"
}

test_link_missing_snippet_fails() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"
    echo "bind = SUPER, Q, killactive" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    if "$SCRIPT" link "${XDG_CONFIG_HOME}/hypr/bindings.conf" > out.log 2> err.log; then
        fail "link succeeded without a tracked snippet"
    fi

    assert_file_contains err.log "Tracked snippet not found"
}

test_apply_command_removed() {
    if "$SCRIPT" apply > out.log 2> err.log; then
        fail "apply command unexpectedly succeeded"
    fi

    assert_file_contains err.log "Unknown command: apply"
}

test_remove_restores_default_and_deletes_snippet() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, brave"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, firefox"
        echo "workspace = 1, monitor:DP-3"
    } > "${XDG_CONFIG_HOME}/hypr/bindings.conf"

    local target="${XDG_CONFIG_HOME}/hypr/bindings.conf"
    local snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"

    "$SCRIPT" add "$target" > add.log
    assert_file_exists "$snippet"
    assert_file_contains "$target" "source = ${snippet}"

    "$SCRIPT" remove "$target" > remove.log

    assert_file_not_exists "$snippet"
    assert_file_contains "$target" "bind = SUPER, B, exec, brave"
    assert_file_not_contains "$target" "source = ${snippet}"
    assert_file_not_contains "$target" "workspace = 1, monitor:DP-3"
    compgen -G "${target}.stomarchy-backup.*" > /dev/null || fail "Expected remove to create a backup"
}

test_remove_untracked_missing_target_restores_default() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty"
    echo 'font-size = 9' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty/config"

    local target="${XDG_CONFIG_HOME}/ghostty/config"

    "$SCRIPT" remove "$target" > remove.log

    assert_file_contains "$target" "font-size = 9"
    assert_file_contains remove.log "No tracked snippet found"
}

test_remove_missing_original_fails() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr"
    echo "workspace = 1" > "${XDG_CONFIG_HOME}/hypr/missing.conf"

    if "$SCRIPT" remove "${XDG_CONFIG_HOME}/hypr/missing.conf" > out.log 2> err.log; then
        fail "remove succeeded without an Omarchy original"
    fi

    assert_file_contains err.log "Omarchy original not found"
}

test_sync_copies_local_defaults_and_reapplies_imports() {
    mkdir -p "${XDG_CONFIG_HOME}/hypr" "${XDG_CONFIG_HOME}/waybar" "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${STOMARCHY_OMARCHY_CONFIG_DIR}/waybar" "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, brave"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, firefox"
        echo "workspace = 1, monitor:DP-3"
    } > "${XDG_CONFIG_HOME}/hypr/bindings.conf"

    echo '{"position": "bottom"}' > "${XDG_CONFIG_HOME}/waybar/config.jsonc"
    echo '{"position": "top"}' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/waybar/config.jsonc"
    echo 'font-size = 9' > "${STOMARCHY_OMARCHY_CONFIG_DIR}/ghostty/config"

    local hypr_target="${XDG_CONFIG_HOME}/hypr/bindings.conf"
    local hypr_snippet="${XDG_CONFIG_HOME}/stomarchy/.config/hypr/bindings.conf"
    local waybar_target="${XDG_CONFIG_HOME}/waybar/config.jsonc"
    local ghostty_target="${XDG_CONFIG_HOME}/ghostty/config"

    "$SCRIPT" add "$hypr_target" > add.log

    {
        echo "bind = SUPER, Q, killactive"
        echo "bind = SUPER, B, exec, zen-browser"
    } > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"

    "$SCRIPT" sync > sync.log

    assert_file_contains "$hypr_target" "bind = SUPER, B, exec, zen-browser"
    assert_file_contains "$hypr_target" "source = ${hypr_snippet}"
    assert_file_not_contains "$hypr_target" "workspace = 1, monitor:DP-3"
    assert_file_contains "$hypr_snippet" "workspace = 1, monitor:DP-3"
    assert_file_contains "$waybar_target" '{"position": "top"}'
    assert_file_not_contains "$waybar_target" '{"position": "bottom"}'
    assert_file_contains "$ghostty_target" "font-size = 9"
    compgen -G "${waybar_target}.stomarchy-backup.*" > /dev/null || fail "Expected sync to back up changed untracked config"
    assert_file_contains sync.log "applied 1 import block"
}

test_sync_missing_omarchy_config_dir_fails() {
    rm -rf "$STOMARCHY_OMARCHY_CONFIG_DIR"

    if "$SCRIPT" sync > out.log 2> err.log; then
        fail "sync succeeded without Omarchy config directory"
    fi

    assert_file_contains err.log "Omarchy config directory not found"
}

test_sync_warns_for_tracked_file_without_original() {
    mkdir -p "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr" "${XDG_CONFIG_HOME}/stomarchy/.config/hypr"
    echo "bind = SUPER, Q, killactive" > "${STOMARCHY_OMARCHY_CONFIG_DIR}/hypr/bindings.conf"
    echo "workspace = 1" > "${XDG_CONFIG_HOME}/stomarchy/.config/hypr/old.conf"

    "$SCRIPT" sync > out.log

    assert_file_contains out.log "Tracked snippet has no current Omarchy original"
}

with_temp_home "rejects outside ~/.config" test_rejects_outside_config
with_temp_home "rejects missing Omarchy original" test_rejects_missing_original
with_temp_home "Hyprland conf snippets include unbinds" test_hypr_conf_snippet
with_temp_home "Hyprland Lua top-level snippets" test_hypr_lua_top_level_snippet
with_temp_home "Hyprland Lua bind replacements" test_hypr_lua_bind_replacement
with_temp_home "Hyprland Lua partial table edits are skipped" test_hypr_lua_partial_table_skip
with_temp_home "unsupported Waybar JSONC fails" test_unsupported_waybar_fails
with_temp_home "add restores originals and is idempotent" test_add_restores_original_and_is_idempotent
with_temp_home "Lua add uses tracked snippet path" test_lua_add_uses_tracked_snippet_path
with_temp_home "link checked-out snippets" test_link_checked_out_snippets
with_temp_home "link single file" test_link_single_file
with_temp_home "link single tracked file" test_link_single_tracked_file
with_temp_home "link ignores git checkout files" test_link_ignores_git_checkout_files
with_temp_home "link missing snippet fails" test_link_missing_snippet_fails
with_temp_home "apply command is removed" test_apply_command_removed
with_temp_home "remove restores default and deletes snippet" test_remove_restores_default_and_deletes_snippet
with_temp_home "remove untracked missing target restores default" test_remove_untracked_missing_target_restores_default
with_temp_home "remove missing original fails" test_remove_missing_original_fails
with_temp_home "sync copies local defaults and reapplies imports" test_sync_copies_local_defaults_and_reapplies_imports
with_temp_home "sync fails without Omarchy config directory" test_sync_missing_omarchy_config_dir_fails
with_temp_home "sync warns for tracked file without original" test_sync_warns_for_tracked_file_without_original

echo "${PASS_COUNT} passed, ${FAIL_COUNT} failed"

[ "$FAIL_COUNT" -eq 0 ]
