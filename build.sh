#!/usr/bin/env bash
# Build facet.mrb from fonts and the main source.
# Font sources must come before facet.rb so their constants
# are defined when facet.rb is evaluated.
set -euo pipefail
cd "$(dirname "$0")"

mrbc -o facet.mrb \
  fonts/terminus_8x16.rb \
  facet.rb

echo "built facet.mrb"
