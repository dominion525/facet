#!/usr/bin/env bash
# Build facet.mrb with Pure Ruby shims that replace several C-implemented
# methods. Same output filename as build.sh; this version reduces the
# C-primitive surface from 27 unique syms to 14 (or 9 excluding I/O).
# See shims.rb for the list and the rationale.
set -euo pipefail
cd "$(dirname "$0")"

mrbc -o facet-shim.mrb \
  fonts/terminus_6x12.rb \
  fonts/terminus_8x16.rb \
  fonts/terminus_12x24.rb \
  fonts/terminus_16x32.rb \
  fonts/shinonome_12x12.rb \
  fonts/shinonome_16x16.rb \
  fonts/sprite_hasumikin.rb \
  slide.rb \
  shims.rb \
  facet/core.rb \
  facet.rb

echo "built facet-shim.mrb"
