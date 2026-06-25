#!/usr/bin/env bash
# Like run.sh, but with shims.rb prepended and test_shims.rb bundled.
# Verifies that shimmed builds still pass the existing smoke / pure /
# render tests AND that each shim itself matches C behavior.
set -euo pipefail
cd "$(dirname "$0")/.."

out=$(mktemp -t facet_test_shim.XXXXXX).mrb
trap 'rm -f "$out"' EXIT

mrbc -o "$out" \
  test/driver.rb \
  test/assert.rb \
  test/helper.rb \
  shims.rb \
  facet/core.rb \
  test/test_*.rb \
  test/finalize.rb

mruby -b "$out"
