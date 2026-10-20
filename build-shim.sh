#!/usr/bin/env bash
# Build facet-shim.mrb: the same sources as build.sh plus shims.rb, which
# redefines 13 C-implemented methods in Pure Ruby so that facet calls fewer
# C primitives. The output sits next to build.sh's facet.mrb.
# See shims.rb for the list.
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
