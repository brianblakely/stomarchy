#!/bin/bash

set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
PACKAGE_PATH=${1:-}

if [[ -z $PACKAGE_PATH ]]; then
  shopt -s nullglob
  packages=("$ROOT_DIR"/stomarchy-0.2.0-*-any.pkg.tar.*)
  shopt -u nullglob
  if ((${#packages[@]} != 1)); then
    printf 'Expected one built Stomarchy 0.2.0 package, found %d\n' "${#packages[@]}" >&2
    exit 1
  fi
  PACKAGE_PATH=${packages[0]}
fi

contents=$(bsdtar -tf "$PACKAGE_PATH")
for expected in \
  usr/bin/stomarchy \
  usr/share/bash-completion/completions/stomarchy \
  usr/share/man/man1/stomarchy.1.gz \
  usr/share/licenses/stomarchy/LICENSE; do
  if ! grep -Fxq "$expected" <<<"$contents"; then
    printf 'Package is missing %s\n' "$expected" >&2
    exit 1
  fi
done

printf 'Package contents verified: %s\n' "$PACKAGE_PATH"
