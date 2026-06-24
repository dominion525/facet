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

# Switch these to other FONT_* / SHINONOME_* constants to change fonts.
TITLE_FONT = FONT_8x16
JP_FONT    = SHINONOME_K12

PAGES = [
  { title: "facet",
    body:  ["the minimal slide tool", "on mruby"] },
  { title: "features",
    body:  ["- alt screen on enter",
            "- restores on exit",
            "- bitmap title via terminus"] },
  { title: "ふぉんと",
    body:  ["jp title via shinonome 12x12",
            "- ひらがな + カタカナ + 1ku"] },
  { title: "last page",
    body:  ["press q + Enter to quit"] },
]

def row_bits(data, offset, bpr)
  row = 0
  i = 0
  while i < bpr
    row = (row << 8) | (data[offset + i] || 0)
    i += 1
  end
  row
end

def row_bits_str(str, offset, bpr)
  row = 0
  i = 0
  while i < bpr
    row = (row << 8) | (str.getbyte(offset + i) || 0)
    i += 1
  end
  row
end

def utf8_codepoints(text)
  result = []
  bs = text.bytes
  i = 0
  len = bs.size
  while i < len
    b = bs[i]
    if b < 0x80
      result << b
      i += 1
    elsif b < 0xE0
      result << (((b & 0x1F) << 6) | (bs[i + 1] & 0x3F))
      i += 2
    elsif b < 0xF0
      result << (((b & 0x0F) << 12) | ((bs[i + 1] & 0x3F) << 6) | (bs[i + 2] & 0x3F))
      i += 3
    else
      result << (((b & 0x07) << 18) | ((bs[i + 1] & 0x3F) << 12) | ((bs[i + 2] & 0x3F) << 6) | (bs[i + 3] & 0x3F))
      i += 4
    end
  end
  result
end

def render_glyph(text, font: TITLE_FONT, color: :yellow)
  w     = font[:width]
  h     = font[:height]
  bpr   = font[:bytes_per_row]
  bpc   = font[:bytes_per_char]
  bit_w = bpr * 8
  bs    = text.bytes
  print COLORS[color]
  r = 0
  while r < h
    bs.each do |cp|
      if cp < 0x20 || cp > 0x7e
        top = 0
        bot = 0
      else
        base = (cp - 0x20) * bpc + r * bpr
        top  = row_bits(font[:data], base, bpr)
        bot  = (r + 1 < h) ? row_bits(font[:data], base + bpr, bpr) : 0
      end
      x = 0
      while x < w
        shift = bit_w - 1 - x
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

def render_jp_glyph(text, font: JP_FONT, color: :yellow)
  w     = font[:width]
  h     = font[:height]
  bpr   = font[:bytes_per_row]
  bit_w = bpr * 8
  cps   = utf8_codepoints(text)
  u2j   = font[:u2j]
  data  = font[:data]
  print COLORS[color]
  r = 0
  while r < h
    cps.each do |cp|
      jis   = u2j[cp]
      bytes = jis ? data[jis] : nil
      if bytes
        top = row_bits_str(bytes, r * bpr, bpr)
        bot = (r + 1 < h) ? row_bits_str(bytes, (r + 1) * bpr, bpr) : 0
      else
        top = 0
        bot = 0
      end
      x = 0
      while x < w
        shift = bit_w - 1 - x
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

def render_title(text)
  if text.bytes.any? { |b| b >= 0x80 }
    render_jp_glyph(text)
  else
    render_glyph(text)
  end
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
  render_title(page[:title])
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
