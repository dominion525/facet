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

# CLI args
#   -c / --calibrate            switch to the calibration screen
#   COLS ROWS                   override SCREEN_COLS / SCREEN_ROWS (positional)
#   --baseline N / -b N         override SPRITE_BASELINE (sprite foot row)
#   --duration N / -d N         override DURATION_SEC (camerlengo goal time)
#                                baseline can be below SCREEN_ROWS, useful for
#                                full-screen terminals where you want the
#                                sprites pinned to the actual bottom edge.
calibrate           = false
sprite_baseline_arg = nil
duration_arg        = nil
positional          = []
i = 0
while i < ARGV.size
  a = ARGV[i]
  if a == "-c" || a == "--calibrate"
    calibrate = true
    i += 1
  elsif (a == "--baseline" || a == "-b") && ARGV[i + 1]
    sprite_baseline_arg = ARGV[i + 1].to_i
    i += 2
  elsif (a == "--duration" || a == "-d") && ARGV[i + 1]
    duration_arg = ARGV[i + 1].to_i
    i += 2
  elsif a.start_with?("-")
    i += 1
  else
    positional << a
    i += 1
  end
end

if positional.size >= 2
  cols_arg = positional[0].to_i
  rows_arg = positional[1].to_i
  SCREEN_COLS = cols_arg if cols_arg > 10
  SCREEN_ROWS = rows_arg if rows_arg > 10
end

if sprite_baseline_arg && sprite_baseline_arg > 10
  SPRITE_BASELINE = sprite_baseline_arg
end

if duration_arg && duration_arg > 0
  DURATION_SEC = duration_arg
end

SPRITE_TOP_ROW = SPRITE_BASELINE - SPRITE_HEIGHT

begin
  print "#{CSI}?1049h"  # DECSET 1049: alt screen
  print "#{CSI}?25l"    # hide cursor

  if calibrate
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
