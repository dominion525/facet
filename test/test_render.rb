# Render tests. We avoid depending on the real font tables by handing
# render_glyph tiny synthetic fonts so each pixel is easy to verify.

# Build a 4x2 ASCII font with one character ("A" at 0x41) wired up
# as the bitmap   "1111"    (= 0xF0 shifted into the top 4 bits)
#                 "1001"    (= 0x90 shifted into the top 4 bits)
def mini_ascii_font
  pad = "\x00" * ((0x41 - 0x20) * 2)
  glyph_a = "\xf0\x90"
  rest = "\x00" * ((0x7e - 0x41) * 2)
  {
    width: 4,
    height: 2,
    bytes_per_row: 1,
    bytes_per_char: 2,
    data: pad + glyph_a + rest,
  }
end

assert("render_glyph: ASCII draws full block / space pattern") do
  out = capture { render_glyph("A", mini_ascii_font, nil, :red, 1) }
  # 1st row of "1111" → 4 full blocks
  # 2nd row of "1001" → block, space, space, block
  assert_include out, "█" * 4
  assert_include out, "█  █"
end

assert("render_glyph: ASCII out-of-range codepoint emits only spaces") do
  out = capture { render_glyph("\x01", mini_ascii_font, nil, :white, 1) }
  assert_false out.include?("█")
end

assert("render_glyph: empty text still emits one row per font height") do
  out = capture { render_glyph("", mini_ascii_font, nil, :white, 1) }
  # 2 newlines (one per row), no glyph blocks
  assert_equal 2, out.count("\n")
  assert_false out.include?("█")
end

assert("render_glyph: jp_font with scale 2 doubles each pixel") do
  # JP-style font: width 2, height 1, bytes_per_row 1 (only top bits used).
  # Single record at JIS 0x2422 ("あ") with bitmap "10" = 0x80.
  jp_font = {
    width: 2,
    height: 1,
    bytes_per_row: 1,
    bytes_per_char: 1,
    data: { 0x2422 => "\x80" },
    u2j: { 0x3042 => 0x2422 },
  }
  out = capture { render_glyph("あ", nil, jp_font, :white, 2) }
  # Source 1 pixel ON + 1 pixel OFF → scaled to 2x2 grid:
  #   "██  "
  #   "██  "
  rows = out.split("\n").reject(&:empty?)
  pixel_rows = rows.select { |l| l.include?("█") }
  assert_equal 2, pixel_rows.length
  pixel_rows.each { |l| assert_include l, "██  " }
end

assert("render_glyph: unmapped jp codepoint is rendered as blank") do
  jp_font = {
    width: 2, height: 1, bytes_per_row: 1, bytes_per_char: 1,
    data: { 0x2422 => "\xff" },
    u2j: { 0x3042 => 0x2422 },
  }
  out = capture { render_glyph("漢", nil, jp_font, :white, 1) }
  assert_false out.include?("█")
end
