# facet - bitmap-titled slide tool on mruby
# Build: ./build.sh   (or: mrbc -o facet.mrb fonts/terminus_8x16.rb facet.rb)
# Run  : mruby -b facet.mrb
# Quit : q + Enter
#
# Font tables are defined in fonts/*.rb and prepended at build time so
# constants like FONT_8x16 are available when this file is evaluated.

STDOUT.sync = true

CSI = "\e["

COLORS = {
  reset:   "#{CSI}0m",
  bold:    "#{CSI}1m",
  dim:     "#{CSI}2m",
  red:     "#{CSI}31m",
  green:   "#{CSI}32m",
  yellow:  "#{CSI}33m",
  blue:    "#{CSI}34m",
  magenta: "#{CSI}35m",
  cyan:    "#{CSI}36m",
  white:   "#{CSI}37m",
}

PAGES = [
  { title: "facet",
    body:  ["the minimal slide tool", "on mruby"] },
  { title: "features",
    body:  ["- alt screen on enter",
            "- restores on exit",
            "- big title via terminus 8x16"] },
  { title: "last page",
    body:  ["press q + Enter to quit"] },
]

def render_glyph(text, color: :yellow)
  font = FONT_8x16
  w    = font[:width]
  h    = font[:height]
  bpc  = font[:bytes_per_char]
  bs   = text.bytes
  print COLORS[color]
  r = 0
  while r < h
    bs.each do |cp|
      if cp < 0x20 || cp > 0x7e
        top = 0
        bot = 0
      else
        base = (cp - 0x20) * bpc
        top  = font[:data][base + r] || 0
        bot  = (r + 1 < h) ? (font[:data][base + r + 1] || 0) : 0
      end
      x = 0
      while x < w
        shift = w - 1 - x
        t = (top >> shift) & 1
        b = (bot >> shift) & 1
        print case [t, b]
              when [1, 1] then "█"
              when [1, 0] then "▀"
              when [0, 1] then "▄"
              else " "
              end
        x += 1
      end
    end
    puts
    r += 2
  end
  print COLORS[:reset]
end

def render_line(line)
  if line.empty?
    puts
  elsif line.start_with?("-")
    rest = line[1..].lstrip
    puts "  #{COLORS[:cyan]}•#{COLORS[:reset]} #{rest}"
  else
    puts "  #{line}"
  end
end

def render(idx)
  print "#{CSI}2J#{CSI}H"
  page = PAGES[idx]
  render_glyph(page[:title], color: :yellow)
  puts
  page[:body].each { |line| render_line(line) }
  puts
  puts "#{COLORS[:dim]}(#{idx + 1}/#{PAGES.length})  h:prev  l:next  q:quit  (then Enter)#{COLORS[:reset]}"
end

begin
  print "#{CSI}?1049h"  # DECSET 1049: alt screen
  print "#{CSI}?25l"    # hide cursor

  idx = 0
  render(idx)

  while (line = STDIN.gets)
    case line.chomp
    when "q"
      break
    when "l"
      idx += 1 if idx < PAGES.length - 1
      render(idx)
    when "h"
      idx -= 1 if idx > 0
      render(idx)
    end
  end
ensure
  print "#{CSI}?25h"    # show cursor
  print "#{CSI}?1049l"  # DECRST 1049: restore screen
end
