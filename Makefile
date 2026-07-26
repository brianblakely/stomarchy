SHELL := /bin/bash

.PHONY: all test lint install-check package package-check

all: test

test:
	./tests/run.sh

lint:
	bash -n stomarchy install.sh tests/run.sh tests/package.sh completions/stomarchy.bash PKGBUILD
	shellcheck stomarchy install.sh tests/run.sh tests/package.sh completions/stomarchy.bash
	mandoc -T lint man/stomarchy.1

install-check:
	stage_dir="$$(mktemp -d)"; \
	trap 'rm -rf -- "$$stage_dir"' EXIT; \
	DESTDIR="$$stage_dir" PREFIX=/usr ./install.sh; \
	test -x "$$stage_dir/usr/bin/stomarchy"; \
	test -f "$$stage_dir/usr/share/bash-completion/completions/stomarchy"; \
	test -f "$$stage_dir/usr/share/man/man1/stomarchy.1"; \
	test -f "$$stage_dir/usr/share/licenses/stomarchy/LICENSE"

package:
	source_dir="$$(mktemp -d)"; \
	trap 'rm -rf -- "$$source_dir"' EXIT; \
	SRCDEST="$$source_dir" makepkg --cleanbuild --force --noconfirm

package-check:
	./tests/package.sh
