#!/bin/bash
# shellcheck disable=SC2030,SC2031

set -uo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
SCRIPT="$ROOT_DIR/stomarchy"
PASS_COUNT=0
FAIL_COUNT=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local message=${3:-"values differ"}

  [[ $actual == "$expected" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_file_exists() {
  [[ -f $1 ]] || fail "Expected regular file: $1"
}

assert_not_exists() {
  [[ ! -e $1 && ! -L $1 ]] || fail "Expected path not to exist: $1"
}

assert_contains() {
  local file=$1
  local text=$2

  grep -Fq -- "$text" "$file" || fail "Expected $file to contain: $text"
}

assert_not_contains() {
  local file=$1
  local text=$2

  if grep -Fq -- "$text" "$file"; then
    fail "Expected $file not to contain: $text"
  fi
}

assert_same() {
  cmp -s -- "$1" "$2" || fail "Expected files to match: $1 and $2"
}

assert_status() {
  local expected=$1
  shift
  local actual

  set +e
  "$@"
  actual=$?
  set -e
  assert_eq "$expected" "$actual" "unexpected exit status for: $*"
}

run_stomarchy() {
  "$SCRIPT" "$@"
}

with_fixture() {
  local name=$1
  local test_function=$2
  local fixture
  local fixture_status

  fixture=$(mktemp -d)

  set +e
  (
    set -euo pipefail
    export TEST_ROOT="$fixture"
    export HOME="$fixture/home"
    export XDG_CONFIG_HOME="$fixture/xdg"
    export XDG_STATE_HOME="$fixture/state"
    export STOMARCHY_OMARCHY_ROOT="$fixture/omarchy"
    unset OMARCHY_PATH STOMARCHY_OMARCHY_CONFIG_DIR NO_COLOR
    mkdir -p "$HOME/.config" "$STOMARCHY_OMARCHY_ROOT/config" "$STOMARCHY_OMARCHY_ROOT/default"
    cd "$fixture"
    "$test_function"
  )
  fixture_status=$?
  set -e

  if ((fixture_status == 0)); then
    printf 'ok - %s\n' "$name"
    ((PASS_COUNT += 1))
  else
    printf 'not ok - %s\n' "$name" >&2
    ((FAIL_COUNT += 1))
  fi

  rm -rf -- "$fixture"
}

test_quattro_root_xdg_and_multiline_lua() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/hypr/bindings.lua"
  local target="$HOME/.config/hypr/bindings.lua"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/hypr/bindings.lua"
  local expected="$TEST_ROOT/expected.lua"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'hl.bind("SUPER, Q", function() hl.killactive() end)\n' >"$original"
  cp "$original" "$target"
  {
    printf 'hl.bind({\n'
    printf '  mods = { "SUPER", "SHIFT" },\n'
    printf '  key = "B",\n'
    printf '}, function()\n'
    printf '  hl.spawn("zen-browser")\n'
    printf 'end)\n'
  } >"$expected"
  cat "$expected" >>"$target"

  STOMARCHY_OMARCHY_ROOT="$STOMARCHY_OMARCHY_ROOT///" \
    run_stomarchy add "$target" --dry-run >dry.log
  assert_not_exists "$tracked"
  assert_not_exists "$XDG_STATE_HOME"

  STOMARCHY_OMARCHY_ROOT="$STOMARCHY_OMARCHY_ROOT///" \
    run_stomarchy add "$target"

  assert_same "$expected" "$tracked"
  assert_contains "$target" "-- BEGIN Stomarchy tweaks"
  assert_contains "$target" "dofile(\"$tracked\")"
  luac -p "$tracked"
  luac -p "$target"
  run_stomarchy status --check --porcelain >status.log
  assert_contains status.log $'~/.config/hypr/bindings.lua\tlinked'
}

test_in_place_edit_is_lossless_failure() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"
  local before

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 11\n' >"$target"
  before=$(sha256sum "$target")

  assert_status 1 run_stomarchy add "$target" >out.log 2>err.log
  assert_eq "$before" "$(sha256sum "$target")" "target changed after rejected add"
  assert_not_exists "$tracked"
  assert_contains err.log "not append-only"
}

test_managed_target_drift_preserves_both_files() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"
  local target_hash
  local tracked_hash

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 9\nfont-size = 11\n' >"$target"
  run_stomarchy add "$target"

  printf '\n# direct target edit\n' >>"$target"
  target_hash=$(sha256sum "$target")
  tracked_hash=$(sha256sum "$tracked")

  assert_status 1 run_stomarchy add "$target" >out.log 2>err.log
  assert_eq "$target_hash" "$(sha256sum "$target")" "drifted target changed"
  assert_eq "$tracked_hash" "$(sha256sum "$tracked")" "tracked tweak changed"
  assert_contains err.log "Managed target drift"
  assert_status 1 run_stomarchy status --check --porcelain >status.log
  assert_contains status.log "drift"
}

test_bashrc_mapping_multiline_and_injection_path() {
  local original="$STOMARCHY_OMARCHY_ROOT/default/bashrc"
  local target="$HOME/.bashrc"
  local special_xdg="$TEST_ROOT/xdg space ' \$(touch SHOULD_NOT_EXIST) \`touch ALSO_NOT\`"
  local tracked

  export XDG_CONFIG_HOME="$special_xdg"
  tracked="$XDG_CONFIG_HOME/stomarchy/.bashrc"

  printf 'BASE_VALUE=quattro\n' >"$original"
  cp "$original" "$target"
  {
    printf 'my_project() {\n'
    # shellcheck disable=SC2016
    printf '  printf "hello %%s\\n" "$BASE_VALUE"\n'
    printf '}\n'
  } >>"$target"

  run_stomarchy add "$target"
  assert_file_exists "$tracked"
  assert_contains "$target" "source "
  bash -n "$target"
  bash --noprofile --norc -c 'source "$1"; my_project' _ "$target" >result.log
  assert_contains result.log "hello quattro"
  assert_not_exists "$TEST_ROOT/SHOULD_NOT_EXIST"
  assert_not_exists "$TEST_ROOT/ALSO_NOT"
}

test_registry_path_quoting_keeps_metacharacters_literal() {
  local special_xdg="$TEST_ROOT/registry space'\" \$(touch PWN) \`touch PWN2\`"
  local rel
  local original
  local target

  export XDG_CONFIG_HOME="$special_xdg"

  for rel in hypr/paths.lua ghostty/config kitty/kitty.conf tmux/tmux.conf foot/foot.ini; do
    original="$STOMARCHY_OMARCHY_ROOT/config/$rel"
    target="$HOME/.config/$rel"
    mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"

    case "$rel" in
      hypr/*.lua)
        printf 'o.general.gaps_in = 5\n' >"$original"
        printf 'o.general.gaps_in = 5\no.general.gaps_out = 8\n' >"$target"
        ;;
      ghostty/config)
        printf 'font-size = 9\n' >"$original"
        printf 'font-size = 9\nfont-size = 11\n' >"$target"
        ;;
      kitty/*.conf)
        printf 'font_size 9\n' >"$original"
        printf 'font_size 9\nfont_size 11\n' >"$target"
        ;;
      tmux/*.conf)
        printf 'set -g status on\n' >"$original"
        printf 'set -g status on\nset -g status off\n' >"$target"
        ;;
      foot/*.ini)
        printf '[main]\nfont=monospace:size=9\n' >"$original"
        printf '[main]\nfont=monospace:size=9\nfont=monospace:size=11\n' >"$target"
        ;;
    esac

    run_stomarchy add "$target"
    assert_contains "$target" "touch PWN"
  done

  luac -p "$HOME/.config/hypr/paths.lua"
  foot -C -c "$HOME/.config/foot/foot.ini"
  assert_not_exists "$TEST_ROOT/PWN"
  assert_not_exists "$TEST_ROOT/PWN2"
}

test_foot_reopens_main_and_validates() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/foot/foot.ini"
  local target="$HOME/.config/foot/foot.ini"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/foot/foot.ini"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  {
    printf '[main]\n'
    printf 'font=monospace:size=9\n'
    printf '\n[scrollback]\n'
    printf 'lines=1000\n'
  } >"$original"
  cp "$original" "$target"
  printf '\n[cursor]\nstyle=beam\n' >>"$target"

  run_stomarchy add "$target"
  assert_contains "$target" "# BEGIN Stomarchy tweaks"
  assert_contains "$target" "[main]"
  assert_contains "$target" "include=$tracked"
  awk -v include_line="include=$tracked" '
    $0 == "[main]" { previous = $0; next }
    $0 == include_line {
      if (previous != "[main]") {
        exit 1
      }
      found = 1
    }
    { previous = $0 }
    END { exit found ? 0 : 1 }
  ' "$target"
  foot -C -c "$target"
}

test_rejects_retired_and_unregistered_adapters() {
  local rel

  for rel in \
    hypr/hyprsunset.conf \
    hypr/xdph.conf \
    uwsm/env \
    hooks/custom.sh \
    waybar/config.jsonc; do
    mkdir -p "$HOME/.config/$(dirname -- "$rel")"
    printf 'value\n' >"$HOME/.config/$rel"
    assert_status 1 run_stomarchy add "$HOME/.config/$rel" >out.log 2>err.log
    assert_contains err.log "Unsupported config adapter"
  done
}

test_inputrc_full_file_lifecycle() {
  local target="$HOME/.inputrc"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.inputrc"
  local expected="$TEST_ROOT/expected"

  printf 'set editing-mode vi\nset completion-ignore-case on\n' >"$target"
  cp "$target" "$expected"
  run_stomarchy add "$target"

  assert_same "$expected" "$target"
  assert_same "$expected" "$tracked"
  assert_not_contains "$target" "\$include"

  printf 'set editing-mode emacs\n' >"$tracked"
  run_stomarchy link "$target"
  assert_same "$tracked" "$target"
  run_stomarchy status --check --porcelain >status.log
  assert_contains status.log $'~/.inputrc\tlinked'

  cp "$target" "$expected"
  run_stomarchy remove "$target"
  assert_not_exists "$tracked"
  assert_same "$expected" "$target"
}

test_uwsm_default_is_full_file() {
  local target="$HOME/.config/uwsm/default"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/uwsm/default"

  mkdir -p "$(dirname -- "$target")"
  printf 'export TERMINAL=xdg-terminal-exec\n' >"$target"
  run_stomarchy add "$target"
  assert_same "$target" "$tracked"

  printf 'export TERMINAL=foot\n' >"$tracked"
  run_stomarchy link
  assert_same "$target" "$tracked"

  run_stomarchy wipe
  assert_same "$target" "$tracked"
}

test_baselines_distinguish_upstream_change_and_drift() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 9\nwindow-padding-x = 8\n' >"$target"
  run_stomarchy add "$target"

  printf 'font-size = 10\n' >"$original"
  assert_status 1 run_stomarchy status --check --porcelain >status.log
  assert_contains status.log "upstream-changed"

  cp "$original" "$target"
  assert_status 1 run_stomarchy status --check --porcelain >reset-status.log
  assert_contains reset-status.log "upstream-changed"
  run_stomarchy add "$target" >reset-add.log
  assert_contains reset-add.log "run 'stomarchy sync'"
  assert_not_contains "$target" "BEGIN Stomarchy tweaks"

  run_stomarchy sync
  assert_contains "$target" "font-size = 10"
  assert_contains "$target" "BEGIN Stomarchy tweaks"

  printf '# direct edit\n' >>"$target"
  cp "$target" drifted
  assert_status 1 run_stomarchy sync >out.log 2>err.log
  assert_same drifted "$target"
  assert_contains err.log "Target drift detected"
}

test_tracked_only_sync_and_wipe_leave_mirror_alone() {
  local lua_original="$STOMARCHY_OMARCHY_ROOT/config/hypr/input.lua"
  local lua_target="$HOME/.config/hypr/input.lua"
  local waybar_original="$STOMARCHY_OMARCHY_ROOT/config/waybar/config.jsonc"
  local waybar_target="$HOME/.config/waybar/config.jsonc"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/hypr/input.lua"

  mkdir -p "$(dirname -- "$lua_original")" "$(dirname -- "$lua_target")"
  mkdir -p "$(dirname -- "$waybar_original")" "$(dirname -- "$waybar_target")"
  printf 'o.input.sensitivity = 0\n' >"$lua_original"
  printf 'o.input.sensitivity = 0\no.input.sensitivity = -0.5\n' >"$lua_target"
  printf '{"position":"top"}\n' >"$waybar_original"
  printf '{"user":"keep"}\n' >"$waybar_target"
  cp "$waybar_target" waybar.expected

  run_stomarchy add "$lua_target"
  printf 'o.input.sensitivity = 1\n' >"$lua_original"
  run_stomarchy sync
  assert_same waybar.expected "$waybar_target"

  run_stomarchy wipe
  assert_same "$lua_original" "$lua_target"
  assert_file_exists "$tracked"
  assert_same waybar.expected "$waybar_target"
}

test_all_requires_force_and_snapshots() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/waybar/config.jsonc"
  local target="$HOME/.config/waybar/config.jsonc"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf '{"position":"top"}\n' >"$original"
  printf '{"position":"bottom"}\n' >"$target"

  assert_status 2 run_stomarchy sync --all >out.log 2>err.log
  assert_contains err.log "requires --force"
  assert_contains "$target" "bottom"

  run_stomarchy sync --all --force >out.log 2>err.log
  assert_same "$original" "$target"
  assert_contains err.log "Recovery snapshot"
  find "$XDG_STATE_HOME/stomarchy/recovery" -path '*/targets/config/waybar/config.jsonc' -type f -print -quit |
    grep -q . || fail "Expected recovery copy of Waybar target"
}

test_all_refuses_retired_tracked_files() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/waybar/config.jsonc"
  local target="$HOME/.config/waybar/config.jsonc"
  local retired="$XDG_CONFIG_HOME/stomarchy/.config/hypr/old.conf"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")" "$(dirname -- "$retired")"
  printf '{"position":"top"}\n' >"$original"
  printf '{"position":"bottom"}\n' >"$target"
  printf 'legacy tracked content\n' >"$retired"

  assert_status 1 run_stomarchy sync --all --force >out.log 2>err.log
  assert_contains err.log "Unsupported tracked file blocks --all"
  assert_contains "$target" "bottom"
  assert_not_exists "$XDG_STATE_HOME/stomarchy/recovery"
}

test_dry_runs_create_no_persistent_files() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/kitty/kitty.conf"
  local target="$HOME/.config/kitty/kitty.conf"

  rm -rf -- "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"
  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font_size 9\n' >"$original"
  printf 'font_size 9\nfont_size 11\n' >"$target"

  run_stomarchy add "$target" --dry-run >out.log
  assert_not_exists "$XDG_CONFIG_HOME"
  assert_not_exists "$XDG_STATE_HOME"
  assert_contains "$target" "font_size 11"
}

test_malformed_markers_are_rejected() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"
  local before

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")" "$(dirname -- "$tracked")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 11\n' >"$tracked"
  {
    cat "$original"
    printf '\n# BEGIN Stomarchy tweaks\n'
    printf '# BEGIN Stomarchy tweaks\n'
    printf 'config-file = "%s"\n' "$tracked"
    printf '# END Stomarchy tweaks\n'
  } >"$target"
  before=$(sha256sum "$target")

  assert_status 1 run_stomarchy link >out.log 2>err.log
  assert_eq "$before" "$(sha256sum "$target")" "malformed target changed"
  assert_contains err.log "Malformed"
}

test_orphaned_valid_marker_is_not_recaptured() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"
  local before

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font-size = 9\n' >"$original"
  {
    cat "$original"
    printf '\n# BEGIN Stomarchy tweaks\n'
    printf 'config-file = "%s"\n' "$tracked"
    printf '# END Stomarchy tweaks\n'
  } >"$target"
  before=$(sha256sum "$target")

  assert_status 1 run_stomarchy add "$target" >out.log 2>err.log
  assert_eq "$before" "$(sha256sum "$target")" "orphaned managed target changed"
  assert_not_exists "$tracked"
  assert_contains err.log "tracked tweak is missing"
}

test_symlink_destination_is_rejected_without_touching_referent() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/kitty/kitty.conf"
  local target="$HOME/.config/kitty/kitty.conf"
  local referent="$TEST_ROOT/referent"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font_size 9\n' >"$original"
  printf 'do not touch\n' >"$referent"
  ln -s "$referent" "$target"

  assert_status 1 run_stomarchy add "$target" >out.log 2>err.log
  assert_contains err.log "symlink"
  assert_contains "$referent" "do not touch"
}

test_symlink_lock_is_rejected_without_truncating_referent() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local referent="$TEST_ROOT/lock-referent"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")" "$XDG_STATE_HOME/stomarchy"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 9\nfont-size = 11\n' >"$target"
  printf 'keep this lock data\n' >"$referent"
  ln -s "$referent" "$XDG_STATE_HOME/stomarchy/lock"

  assert_status 1 run_stomarchy add "$target" >out.log 2>err.log
  assert_contains err.log "Mutation lock is a symlink"
  assert_contains "$referent" "keep this lock data"
  assert_contains "$target" "font-size = 11"
}

test_bulk_preflight_failure_changes_nothing() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"
  local unsupported="$XDG_CONFIG_HOME/stomarchy/.config/hypr/old.conf"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$tracked")" "$(dirname -- "$unsupported")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 11\n' >"$tracked"
  printf 'legacy\n' >"$unsupported"

  assert_status 1 run_stomarchy link >out.log 2>err.log
  assert_not_exists "$target"
  assert_contains err.log "Unsupported tracked adapter"
  assert_contains err.log "no tracked targets were changed"
}

test_read_only_original_and_failed_remove_restore() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/kitty/kitty.conf"
  local target="$HOME/.config/kitty/kitty.conf"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/kitty/kitty.conf"
  local target_dir

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font_size 9\n' >"$original"
  chmod 444 "$original"
  printf 'font_size 9\nfont_size 11\n' >"$target"
  run_stomarchy add "$target"
  assert_file_exists "$tracked"

  target_dir=$(dirname -- "$target")
  chmod 500 "$target_dir"
  set +e
  run_stomarchy remove "$target" >out.log 2>err.log
  remove_status=$?
  set -e
  chmod 700 "$target_dir"
  assert_eq 1 "$remove_status" "remove unexpectedly succeeded with unwritable target directory"
  assert_file_exists "$tracked"
}

test_force_link_snapshots_conflict() {
  local original="$STOMARCHY_OMARCHY_ROOT/config/ghostty/config"
  local target="$HOME/.config/ghostty/config"
  local tracked="$XDG_CONFIG_HOME/stomarchy/.config/ghostty/config"

  mkdir -p "$(dirname -- "$original")" "$(dirname -- "$target")"
  printf 'font-size = 9\n' >"$original"
  printf 'font-size = 9\nfont-size = 11\n' >"$target"
  run_stomarchy add "$target"
  printf '# drift\n' >>"$target"

  run_stomarchy link "$target" --force >out.log 2>err.log
  assert_not_contains "$target" "# drift"
  assert_contains "$target" "config-file"
  find "$XDG_STATE_HOME/stomarchy/recovery" -path '*/targets/config/ghostty/config' -type f -print -quit |
    grep -q . || fail "Expected forced-link target snapshot"
  assert_file_exists "$tracked"
}

test_cli_contract_and_deprecated_preview() {
  local command

  assert_eq "stomarchy 0.2.0" "$(run_stomarchy --version)"
  run_stomarchy --help >main.help
  assert_contains main.help "hypr/*.lua"
  assert_contains main.help "sync and wipe are tracked-only"
  assert_contains main.help "STOMARCHY_OMARCHY_ROOT"
  for command in add link remove sync wipe status; do
    run_stomarchy "$command" --help >"$command.help"
    assert_contains "$command.help" "Usage: stomarchy $command"
  done

  assert_status 2 run_stomarchy status extra >out.log 2>err.log
  assert_status 2 run_stomarchy sync operand >out.log 2>err.log
  run_stomarchy sync --preview >out.log 2>err.log
  assert_contains err.log "deprecated"
  assert_not_contains err.log $'\033'
}

test_install_is_relative_staged_and_versioned() {
  local stage="$TEST_ROOT/stage"

  (
    cd /
    DESTDIR="$stage" PREFIX=/usr "$ROOT_DIR/install.sh" >"$TEST_ROOT/install.log"
  )

  assert_file_exists "$stage/usr/bin/stomarchy"
  assert_file_exists "$stage/usr/share/bash-completion/completions/stomarchy"
  assert_file_exists "$stage/usr/share/man/man1/stomarchy.1"
  assert_file_exists "$stage/usr/share/licenses/stomarchy/LICENSE"
  assert_eq "stomarchy 0.2.0" "$("$stage/usr/bin/stomarchy" --version)"
}

test_distribution_version_and_checksum_contract() {
  local expected
  local actual
  local -a source_files=(
    "$ROOT_DIR/stomarchy"
    "$ROOT_DIR/completions/stomarchy.bash"
    "$ROOT_DIR/man/stomarchy.1"
    "$ROOT_DIR/LICENSE"
  )
  local -a package_hashes=()
  local file

  assert_contains "$ROOT_DIR/stomarchy" 'VERSION="0.2.0"'
  assert_contains "$ROOT_DIR/PKGBUILD" 'pkgver=0.2.0'
  assert_contains "$ROOT_DIR/man/stomarchy.1" '"stomarchy 0.2.0"'

  while IFS= read -r expected; do
    package_hashes+=("$expected")
  done < <(sed -n "/^sha256sums=(/,/^)/s/.*'\\([[:xdigit:]]\\{64\\}\\)'.*/\\1/p" "$ROOT_DIR/PKGBUILD")

  assert_eq 4 "${#package_hashes[@]}" "PKGBUILD checksum count"
  for file in "${!source_files[@]}"; do
    actual=$(sha256sum "${source_files[$file]}")
    actual=${actual%% *}
    assert_eq "${package_hashes[$file]}" "$actual" "PKGBUILD checksum mismatch"
  done
}

test_completion_preserves_spaces() {
  local found=false
  local completion

  # shellcheck disable=SC1091
  source "$ROOT_DIR/completions/stomarchy.bash"
  touch "file with spaces.lua"
  COMP_WORDS=(stomarchy add file)
  COMP_CWORD=2
  _stomarchy

  for completion in "${COMPREPLY[@]}"; do
    if [[ $completion == "file with spaces.lua" ]]; then
      found=true
    fi
  done
  [[ $found == true ]] || fail "Completion split a filename containing spaces"
}

test_compat_config_override_and_bash_root() {
  local override="$TEST_ROOT/compat/config"
  local target="$HOME/.config/ghostty/config"

  mkdir -p "$override/ghostty" "$(dirname -- "$target")"
  printf 'font-size = 7\n' >"$override/ghostty/config"
  printf 'font-size = 7\nfont-size = 12\n' >"$target"

  STOMARCHY_OMARCHY_CONFIG_DIR="$override/" \
    STOMARCHY_OMARCHY_ROOT="$STOMARCHY_OMARCHY_ROOT/" \
    run_stomarchy add "$target"
  assert_contains "$target" "BEGIN Stomarchy tweaks"

  printf 'BASE=from-default\n' >"$STOMARCHY_OMARCHY_ROOT/default/bashrc"
  printf 'BASE=from-default\nEXTRA=yes\n' >"$HOME/.bashrc"
  STOMARCHY_OMARCHY_CONFIG_DIR="$override/" \
    STOMARCHY_OMARCHY_ROOT="$STOMARCHY_OMARCHY_ROOT/" \
    run_stomarchy add "$HOME/.bashrc"
  assert_contains "$HOME/.bashrc" "BASE=from-default"
}

test_sibling_quattro_contract() {
  local quattro=${STOMARCHY_QUATTRO_CHECKOUT:-"$ROOT_DIR/../omarchy"}
  local target
  local tracked

  if [[ ! -f $quattro/version ]]; then
    printf 'skip: sibling Quattro checkout not present at %s\n' "$quattro"
    return 0
  fi
  assert_eq "4.0.0.alpha" "$(<"$quattro/version")"
  assert_file_exists "$quattro/default/bashrc"
  assert_file_exists "$quattro/config/hypr/hyprland.lua"
  assert_file_exists "$quattro/config/hypr/hyprsunset.conf"
  assert_file_exists "$quattro/config/hypr/xdph.conf"
  assert_file_exists "$quattro/default/uwsm/default"

  export STOMARCHY_OMARCHY_ROOT="$quattro///"
  target="$HOME/.config/hypr/hyprland.lua"
  tracked="$XDG_CONFIG_HOME/stomarchy/.config/hypr/hyprland.lua"
  mkdir -p "$(dirname -- "$target")"
  cp "$quattro/config/hypr/hyprland.lua" "$target"
  printf '\no.general.gaps_in = 4\n' >>"$target"
  run_stomarchy add "$target"
  assert_contains "$tracked" "o.general.gaps_in = 4"
  luac -p "$target"
}

with_fixture "Quattro root, custom XDG storage, and multiline Lua" test_quattro_root_xdg_and_multiline_lua
with_fixture "in-place edits fail without data loss" test_in_place_edit_is_lossless_failure
with_fixture "managed target drift preserves both files" test_managed_target_drift_preserves_both_files
with_fixture "bashrc mapping and injection-shaped storage path" test_bashrc_mapping_multiline_and_injection_path
with_fixture "registry path quoting keeps metacharacters literal" test_registry_path_quoting_keeps_metacharacters_literal
with_fixture "Foot reopens main and validates assembled config" test_foot_reopens_main_and_validates
with_fixture "retired and unregistered adapters are rejected" test_rejects_retired_and_unregistered_adapters
with_fixture "inputrc full-file lifecycle" test_inputrc_full_file_lifecycle
with_fixture "uwsm/default is a full-file adapter" test_uwsm_default_is_full_file
with_fixture "baseline hashes distinguish upstream change and drift" test_baselines_distinguish_upstream_change_and_drift
with_fixture "tracked-only sync and wipe leave mirror files alone" test_tracked_only_sync_and_wipe_leave_mirror_alone
with_fixture "--all requires force and snapshots" test_all_requires_force_and_snapshots
with_fixture "--all refuses retired tracked files" test_all_refuses_retired_tracked_files
with_fixture "dry runs create no persistent files" test_dry_runs_create_no_persistent_files
with_fixture "malformed markers are rejected" test_malformed_markers_are_rejected
with_fixture "orphaned valid marker is not recaptured" test_orphaned_valid_marker_is_not_recaptured
with_fixture "symlink destination is rejected" test_symlink_destination_is_rejected_without_touching_referent
with_fixture "symlink mutation lock is rejected" test_symlink_lock_is_rejected_without_truncating_referent
with_fixture "bulk preflight failure changes nothing" test_bulk_preflight_failure_changes_nothing
with_fixture "read-only original and failed restore safety" test_read_only_original_and_failed_remove_restore
with_fixture "forced link snapshots conflicts" test_force_link_snapshots_conflict
with_fixture "CLI contract and deprecated preview" test_cli_contract_and_deprecated_preview
with_fixture "installer is checkout-relative, staged, and versioned" test_install_is_relative_staged_and_versioned
with_fixture "distribution version and checksum contract" test_distribution_version_and_checksum_contract
with_fixture "completion preserves spaces" test_completion_preserves_spaces
with_fixture "compat config override and bash root mapping" test_compat_config_override_and_bash_root
with_fixture "sibling Quattro checkout contract" test_sibling_quattro_contract

printf '%d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0))
