#!/usr/bin/env bash
# Build facet.mrb. Font tables in fonts/ are prepended before facet.rb so
# their constants (FONT_6x12, FONT_8x16, FONT_12x24, FONT_16x32) are
# defined when facet.rb is evaluated.
#
# The four sizes match what picoruby-terminus exposes, so any Rapicco-style
# `{font=terminus_NxM}` choice within that set is reachable from code.
set -euo pipefail
cd "$(dirname "$0")"

mrbc -o facet.mrb \
  fonts/terminus_6x12.rb \
  fonts/terminus_8x16.rb \
  fonts/terminus_12x24.rb \
  fonts/terminus_16x32.rb \
  fonts/shinonome_12x12.rb \
  fonts/shinonome_16x16.rb \
  fonts/sprite_hasumikin.rb \
  slide.rb \
  facet.rb

echo "built facet.mrb"
