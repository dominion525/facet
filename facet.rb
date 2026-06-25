# facet - bitmap-titled slide tool on mruby
# Build: ./build.sh
# Run  : mruby -b facet.mrb
# Quit : q + Enter
#
# Content and the things you usually tweak (PAGES, TITLE_FONT, SCREEN_COLS,
# DURATION_SEC, etc.) live in slide.rb. Reusable rendering functions and
# common constants live in facet/core.rb. This file is the entry point:
# it parses CLI args, derives JP_FONT / SPRITE_TOP_ROW from slide.rb, and
# runs either the calibration screen or the main slide loop.

# TITLE_FONT comes from slide.rb. JP_FONT / JP_SCALE follow its height:
# 24 / 32 sizes are produced by integer-scaling the 12 / 16 source bitmaps.
JP_FONT, JP_SCALE = case TITLE_FONT[:height]
                    when 12 then [SHINONOME_K12, 1]
                    when 16 then [SHINONOME_K16, 1]
                    when 24 then [SHINONOME_K12, 2]
                    when 32 then [SHINONOME_K16, 2]
                    end

START_TIME = Time.now.to_i

# CLI args (parsed by parse_args in facet/core.rb)
#   -c / --calibrate            switch to the calibration screen
#   COLS ROWS                   override SCREEN_COLS / SCREEN_ROWS (positional)
#   --baseline N / -b N         override SPRITE_BASELINE (sprite foot row)
#                                can be below SCREEN_ROWS, useful for
#                                full-screen terminals where you want the
#                                sprites pinned to the actual bottom edge.
#   --duration N / -d N         override DURATION_SEC (camerlengo goal time)
OPTS = parse_args(ARGV)

SCREEN_COLS     = OPTS[:cols]     if OPTS[:cols]     && OPTS[:cols]     > 10
SCREEN_ROWS     = OPTS[:rows]     if OPTS[:rows]     && OPTS[:rows]     > 10
SPRITE_BASELINE = OPTS[:baseline] if OPTS[:baseline] && OPTS[:baseline] > 10
DURATION_SEC    = OPTS[:duration] if OPTS[:duration] && OPTS[:duration] > 0

SPRITE_TOP_ROW = SPRITE_BASELINE - SPRITE_HEIGHT

begin
  print "#{CSI}?1049h"  # DECSET 1049: alt screen
  print "#{CSI}?25l"    # hide cursor

  if OPTS[:calibrate]
    render_calibration
    STDIN.gets
  else
    idx = 0
    render(idx)

    while (line = STDIN.gets)
      case line.chomp
      when "q"
        break
      when "l", ""
        idx += 1 if idx < PAGES.length - 1
        render(idx)
      when "h"
        idx -= 1 if idx > 0
        render(idx)
      end
    end
  end
ensure
  print "#{CSI}?25h"    # show cursor
  print "#{CSI}?1049l"  # DECRST 1049: restore screen
end
