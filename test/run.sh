#!/usr/bin/env bash
# Build a single .mrb that bundles the test driver, the vendored mruby
# assert.rb, every test_*.rb under test/, and finalize.rb (which calls
# report() and exits with non-zero on failure).
set -euo pipefail
cd "$(dirname "$0")/.."

out=$(mktemp -t facet_test.XXXXXX).mrb
trap 'rm -f "$out"' EXIT

mrbc -o "$out" \
  test/driver.rb \
  test/assert.rb \
  facet/core.rb \
  test/test_*.rb \
  test/finalize.rb

mruby -b "$out"
