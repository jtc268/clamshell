.PHONY: build package smoke helper install

build:
	swift build -c release

package:
	./scripts/package_app.sh

helper:
	mkdir -p dist
	clang -O2 -Wall -Wextra helper/clamshell-helper.c -o dist/clamshell-helper

smoke:
	./scripts/smoke_test.sh

install:
	./install.sh
