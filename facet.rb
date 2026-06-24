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

# Switch TITLE_FONT to another FONT_NxM and JP_FONT/JP_SCALE will follow
# the corresponding shinonome size (24/32 are produced by integer-scaling
# the 12/16 source bitmaps).
TITLE_FONT = FONT_8x16

JP_FONT, JP_SCALE = case TITLE_FONT[:height]
                    when 12 then [SHINONOME_K12, 1]
                    when 16 then [SHINONOME_K16, 1]
                    when 24 then [SHINONOME_K12, 2]
                    when 32 then [SHINONOME_K16, 2]
                    end

DURATION_SEC  = 300
SCREEN_COLS   = 120
SPRITE_HEIGHT = 11
START_TIME    = Time.now.to_i

BODY_EN_FONT = FONT_6x12
BODY_JP_FONT = SHINONOME_K12

PAGES = [
  { title: "facet",
    body:  ["",
            "  a minimal slide tool",
            "  written in pure mruby",
            "",
            "  l + Enter to go forward"] },

  { title: "design",
    body:  ["- mruby subset only",
            "- no filesystem, no signals",
            "- pages embedded as ruby literals",
            "- stdin and stdout only"] },

  { title: "keys",
    body:  ["- h + Enter  : previous page",
            "- l + Enter  : next page",
            "- q + Enter  : quit",
            "",
            "  line-buffered. no stty needed"] },

  { title: "ascii font",
    body:  ["- terminus 4.49.1, 4 sizes bundled",
            "    6x12 / 8x16 / 12x24 / 16x32",
            "- block character (UPPER / LOWER / FULL)",
            "- glyphs packed as string literals in fonts/"] },

  { title: "decoration",
    body:  ["- bullet lines render as cyan dots",
            "- non-bullet lines stay plain",
            "- title color is yellow + bold",
            "- footer dimmed"] },

  { title: "東雲フォント",
    body:  ["- shinonome 0.9.11 を取り込み",
            "- ひらがな ・ カタカナ ・ 第1水準漢字",
            "- 12x12 と 16x16 を内蔵",
            "- 24x24 と 32x32 は整数倍スケールで描画"] },

  { title: "漢字混在",
    body:  ["- title に漢字が来ても block 描画される",
            "- 本文は ANSI text としてそのまま出る",
            "- 端末側のフォントに依存する"] },

  { title: "build",
    body:  ["- `./build.sh` で facet.mrb を生成",
            "- fonts/*.rb を先に並べて 1 ファイルに mrbc",
            "- 大きいデータは chunk 化して unpack する"] },

  { title: "facet",
    body:  ["",
            "  end of demo",
            "",
            "  q + Enter to quit"] },
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

def render_jp_glyph(text, font: JP_FONT, color: :yellow, scale: JP_SCALE)
  w        = font[:width]
  h        = font[:height]
  bpr      = font[:bytes_per_row]
  bit_w    = bpr * 8
  cps      = utf8_codepoints(text)
  u2j      = font[:u2j]
  data     = font[:data]
  scaled_w = w * scale
  scaled_h = h * scale
  print COLORS[color]
  r = 0
  while r < scaled_h
    cps.each do |cp|
      jis   = u2j[cp]
      bytes = jis ? data[jis] : nil
      orig_top = r / scale
      orig_bot = (r + 1) / scale
      if bytes
        top = orig_top < h ? row_bits_str(bytes, orig_top * bpr, bpr) : 0
        bot = orig_bot < h ? row_bits_str(bytes, orig_bot * bpr, bpr) : 0
      else
        top = 0
        bot = 0
      end
      x = 0
      while x < scaled_w
        orig_x = x / scale
        shift  = bit_w - 1 - orig_x
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

def sprite_width(rows)
  w = 0
  rows.each { |r| w = r.length if r.length > w }
  w
end

# Draws a sprite (array of pixel rows) at column x of the current cursor row.
# Each non-"." char looks up a 256-color background from SPRITE_PALETTE.
# After drawing, the cursor sits two lines below the sprite.
def render_sprite(rows, x)
  rows.each do |row|
    print "#{CSI}#{x}G"
    prev = nil
    i = 0
    len = row.length
    while i < len
      ch = row[i]
      if ch == "."
        n = 1
        while i + n < len && row[i + n] == "."
          n += 1
        end
        print "#{CSI}0m" if prev
        prev = nil
        print "#{CSI}#{n}C"
        i += n
      else
        color = SPRITE_PALETTE[ch]
        if color != prev
          print "#{CSI}48;5;#{color}m"
          prev = color
        end
        print " "
        i += 1
      end
    end
    print "#{CSI}0m" if prev
    puts
  end
end

def fmt_time(sec)
  m, s = sec.divmod(60)
  "%d:%02d" % [m, s]
end

def render_mixed_glyph(text, en_font: BODY_EN_FONT, jp_font: BODY_JP_FONT, color: :white)
  h     = en_font[:height]
  bpr_e = en_font[:bytes_per_row]
  bpr_j = jp_font[:bytes_per_row]
  bit_e = bpr_e * 8
  bit_j = bpr_j * 8
  w_e   = en_font[:width]
  w_j   = jp_font[:width]
  bpc_e = en_font[:bytes_per_char]
  data_e = en_font[:data]
  data_j = jp_font[:data]
  u2j    = jp_font[:u2j]
  cps   = utf8_codepoints(text)
  print COLORS[color]
  r = 0
  while r < h
    cps.each do |cp|
      if cp < 0x80
        if cp >= 0x20 && cp <= 0x7e
          base = (cp - 0x20) * bpc_e
          top = data_e[base + r] || 0
          bot = (r + 1 < h) ? (data_e[base + r + 1] || 0) : 0
        else
          top = 0
          bot = 0
        end
        x = 0
        while x < w_e
          shift = bit_e - 1 - x
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
      else
        jis = u2j[cp]
        bytes = jis ? data_j[jis] : nil
        if bytes
          top = row_bits_str(bytes, r * bpr_j, bpr_j)
          bot = (r + 1 < h) ? row_bits_str(bytes, (r + 1) * bpr_j, bpr_j) : 0
        else
          top = 0
          bot = 0
        end
        x = 0
        while x < w_j
          shift = bit_j - 1 - x
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
    end
    puts
    r += 2
  end
  print COLORS[:reset]
end

def render_line(line)
  if line.empty?
    puts
    puts
    puts
  elsif line.start_with?("-")
    rest = line[1..].lstrip
    render_mixed_glyph("• #{rest}", color: :cyan)
  else
    render_mixed_glyph("  #{line}")
  end
end

def render(idx)
  print "#{CSI}2J#{CSI}H"
  page = PAGES[idx]
  render_title(page[:title])
  puts
  page[:body].each { |line| render_line(line) }
  puts
  page_pct = (idx + 1) * 100 / PAGES.length
  elapsed  = Time.now.to_i - START_TIME
  time_pct = elapsed * 100 / DURATION_SEC
  time_pct = 100 if time_pct > 100

  rapiko_w = sprite_width(SPRITE_RAPIKO)
  rapiko_x = 1 + (SCREEN_COLS - rapiko_w) * page_pct / 100
  render_sprite(SPRITE_RAPIKO, rapiko_x)
  print "#{CSI}#{SPRITE_HEIGHT}A"

  camerlengo_w = sprite_width(SPRITE_CAMERLENGO)
  camerlengo_x = 1 + (SCREEN_COLS - camerlengo_w) * time_pct / 100
  render_sprite(SPRITE_CAMERLENGO, camerlengo_x)

  puts
  puts "#{COLORS[:dim]}(#{idx + 1}/#{PAGES.length})  page #{page_pct}%  time #{fmt_time(elapsed)}/#{fmt_time(DURATION_SEC)}  Enter or l:next  h:prev  q:quit#{COLORS[:reset]}"
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
    when "l", ""
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
