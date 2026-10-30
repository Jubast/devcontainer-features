#!/bin/bash
set -e

source dev-container-features-test-lib

fails() { ! "$@"; }

d="$(mktemp -d)"
cd "$d"

check "yamllint on PATH" command -v yamllint
check "yamllint runs" yamllint --version

printf -- '---\na: 1\n' > ok.yml
printf 'a: [1\n' > bad.yml
check "yamllint accepts valid yaml" yamllint ok.yml
check "yamllint rejects broken yaml" fails yamllint bad.yml

reportResults
