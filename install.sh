#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

if (($# > 0)); then
  case "$1" in
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh

Install Stomarchy, its Bash completion, man page, and license.

Environment:
  PREFIX   Installation prefix. Defaults to ~/.local for non-root users and
           /usr/local for root.
  DESTDIR  Optional staging root prepended to every installed path.
EOF
      exit 0
      ;;
    *)
      printf 'install.sh: unexpected argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
fi

if [[ -v PREFIX ]]; then
  INSTALL_PREFIX=${PREFIX%/}
elif ((EUID == 0)); then
  INSTALL_PREFIX=/usr/local
else
  INSTALL_PREFIX="$HOME/.local"
fi

if [[ -z $INSTALL_PREFIX ]]; then
  INSTALL_PREFIX=/
fi

STAGE_ROOT=${DESTDIR:-}
BIN_PATH="$STAGE_ROOT$INSTALL_PREFIX/bin/stomarchy"
COMPLETION_PATH="$STAGE_ROOT$INSTALL_PREFIX/share/bash-completion/completions/stomarchy"
MAN_PATH="$STAGE_ROOT$INSTALL_PREFIX/share/man/man1/stomarchy.1"
LICENSE_PATH="$STAGE_ROOT$INSTALL_PREFIX/share/licenses/stomarchy/LICENSE"

install -Dm755 "$SCRIPT_DIR/stomarchy" "$BIN_PATH"
install -Dm644 "$SCRIPT_DIR/completions/stomarchy.bash" "$COMPLETION_PATH"
install -Dm644 "$SCRIPT_DIR/man/stomarchy.1" "$MAN_PATH"
install -Dm644 "$SCRIPT_DIR/LICENSE" "$LICENSE_PATH"

printf 'Installed Stomarchy under %s\n' "$STAGE_ROOT$INSTALL_PREFIX"
printf '  %s\n' "$BIN_PATH" "$COMPLETION_PATH" "$MAN_PATH" "$LICENSE_PATH"
