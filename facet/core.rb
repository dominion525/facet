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
def row_bits(str, offset, bpr)
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
        bits = 0
      else
        bits = row_bits(font[:data], (cp - 0x20) * bpc + r * bpr, bpr)
      end
      x = 0
      while x < w
        shift = bit_w - 1 - x
        print ((bits >> shift) & 1 == 1) ? "█" : " "
        x += 1
      end
    end
    puts
    r += 1
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
      orig  = r / scale
      bits  = (bytes && orig < h) ? row_bits(bytes, orig * bpr, bpr) : 0
      x = 0
      while x < scaled_w
        shift = bit_w - 1 - (x / scale)
        print ((bits >> shift) & 1 == 1) ? "█" : " "
        x += 1
      end
    end
    puts
    r += 1
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
          bits = row_bits(data_e, (cp - 0x20) * bpc_e + r * bpr_e, bpr_e)
        else
          bits = 0
        end
        x = 0
        while x < w_e
          shift = bit_e - 1 - x
          print ((bits >> shift) & 1 == 1) ? "█" : " "
          x += 1
        end
      else
        jis = u2j[cp]
        bytes = jis ? data_j[jis] : nil
        bits = bytes ? row_bits(bytes, r * bpr_j, bpr_j) : 0
        x = 0
        while x < w_j
          shift = bit_j - 1 - x
          print ((bits >> shift) & 1 == 1) ? "█" : " "
          x += 1
        end
      end
    end
    puts
    r += 1
  end
  print COLORS[:reset]
end

def render_line(line)
  if line.empty?
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

  page_pct = PAGES.length > 1 ? idx * 100 / (PAGES.length - 1) : 0
  elapsed  = Time.now.to_i - START_TIME
  time_pct = elapsed * 100 / DURATION_SEC
  time_pct = 100 if time_pct > 100

  rapiko_w  = sprite_width(SPRITE_RAPIKO)
  rapiko_x  = 1 + (SCREEN_COLS - rapiko_w) * page_pct / 100
  rapiko_y  = SPRITE_TOP_ROW + (SPRITE_HEIGHT - SPRITE_RAPIKO.size)
  print "#{CSI}#{rapiko_y};1H"
  render_sprite(SPRITE_RAPIKO, rapiko_x)

  camerlengo_w = sprite_width(SPRITE_CAMERLENGO)
  camerlengo_x = 1 + (SCREEN_COLS - camerlengo_w) * time_pct / 100
  camerlengo_y = SPRITE_TOP_ROW + (SPRITE_HEIGHT - SPRITE_CAMERLENGO.size)
  print "#{CSI}#{camerlengo_y};1H"
  render_sprite(SPRITE_CAMERLENGO, camerlengo_x)
end

# Calibration screen: paints a "+" at each of the 4 SCREEN_COLS x SCREEN_ROWS
# corners and rulers along the top/left edges so you can match the constants
# in slide.rb to your actual terminal size.
def render_calibration
  print "#{CSI}2J#{CSI}H"

  print "#{CSI}1;1H+"
  print "#{CSI}1;#{SCREEN_COLS}H+"
  print "#{CSI}#{SCREEN_ROWS};1H+"
  print "#{CSI}#{SCREEN_ROWS};#{SCREEN_COLS}H+"

  print "#{CSI}1;2H"
  c = 2
  while c < SCREEN_COLS
    if c % 10 == 0
      print((c / 10) % 10)
    elsif c % 5 == 0
      print "+"
    else
      print "-"
    end
    c += 1
  end

  r = 2
  while r < SCREEN_ROWS
    print "#{CSI}#{r};1H"
    if r % 10 == 0
      print((r / 10) % 10)
    elsif r % 5 == 0
      print "+"
    else
      print "|"
    end
    r += 1
  end

  # bitmap で実際の描画パスを使う。タイトル font + 本文 font + 日本語と
  # 「何行入るか」を同時に確認できる。
  # 通常の render() と同じく、タイトル直後は puts 1 行ぶんだけ空けてから
  # body を積む。"空行をたっぷり入れるかどうか" は PAGES 側の自由。
  print "#{CSI}5;3H"
  render_title("calib  #{SCREEN_COLS}x#{SCREEN_ROWS}  base=#{SPRITE_BASELINE}")
  puts
  body_capacity = (SPRITE_TOP_ROW - 5 - 16 - 1) / 12
  body_capacity = 1 if body_capacity < 1
  en_per_line = SCREEN_COLS / BODY_EN_FONT[:width]
  jp_per_line = SCREEN_COLS / BODY_JP_FONT[:width]
  facts = [
    "  日本語混在 漢字 ひらがな カタカナ あいう abc XYZ 0123456789",
    "  width: #{en_per_line} ascii or #{jp_per_line} jp chars per line",
    "  title #{TITLE_FONT[:width]}x#{TITLE_FONT[:height]}  body #{BODY_EN_FONT[:width]}x#{BODY_EN_FONT[:height]} (en) / #{BODY_JP_FONT[:width]}x#{BODY_JP_FONT[:height]} (jp)",
    "  capacity: #{body_capacity} body rows, sprite top y=#{SPRITE_TOP_ROW}",
    "  DURATION_SEC=#{DURATION_SEC}",
  ]
  i = 1
  while i <= body_capacity
    line = facts[i - 1] || "  row #{i}"
    render_mixed_glyph(line)
    i += 1
  end

  # スプライトも本番と同じ位置（左端と右端）に置く。
  rapiko_y = SPRITE_TOP_ROW + (SPRITE_HEIGHT - SPRITE_RAPIKO.size)
  print "#{CSI}#{rapiko_y};1H"
  render_sprite(SPRITE_RAPIKO, 1)

  camerlengo_w = sprite_width(SPRITE_CAMERLENGO)
  camerlengo_x = SCREEN_COLS - camerlengo_w
  camerlengo_y = SPRITE_TOP_ROW + (SPRITE_HEIGHT - SPRITE_CAMERLENGO.size)
  print "#{CSI}#{camerlengo_y};1H"
  render_sprite(SPRITE_CAMERLENGO, camerlengo_x)
end
