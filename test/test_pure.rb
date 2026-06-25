# Pure-function tests for facet/core.rb.
# render_* are not exercised here because they print to stdout and need
# font globals; we cover the side-effect-free helpers instead.

assert('utf8_codepoints: ASCII passthrough') do
  assert_equal [0x61, 0x62, 0x63], utf8_codepoints("abc")
end

assert('utf8_codepoints: 3-byte hiragana') do
  assert_equal [0x3042], utf8_codepoints("あ")
end

assert('utf8_codepoints: 3-byte kanji') do
  assert_equal [0x6771, 0x96F2], utf8_codepoints("東雲")
end

assert('utf8_codepoints: ASCII + JP mixed') do
  assert_equal [0x61, 0x3042, 0x62], utf8_codepoints("aあb")
end

assert('utf8_codepoints: empty string') do
  assert_equal [], utf8_codepoints("")
end

assert('row_bits: single byte') do
  assert_equal 0x12, row_bits("\x12\x34", 0, 1)
end

assert('row_bits: two bytes pad to a 16-bit int') do
  assert_equal 0x1234, row_bits("\x12\x34", 0, 2)
end

assert('row_bits: respects offset') do
  assert_equal 0x1234, row_bits("\xFF\x12\x34", 1, 2)
end

assert('row_bits: out-of-range bytes default to 0') do
  assert_equal 0x1200, row_bits("\x12", 0, 2)
end

assert('sprite_width: max row length wins') do
  assert_equal 5, sprite_width(["abc", "de", "abcde"])
end

assert('sprite_width: empty rows count as 0') do
  assert_equal 3, sprite_width(["", "abc", ""])
end

assert('sprite_width: all empty') do
  assert_equal 0, sprite_width(["", "", ""])
end

assert('parse_args: empty argv') do
  r = parse_args([])
  assert_equal false, r[:calibrate]
  assert_nil r[:baseline]
  assert_nil r[:duration]
  assert_nil r[:cols]
  assert_nil r[:rows]
end

assert('parse_args: short flag -c') do
  assert_equal true, parse_args(["-c"])[:calibrate]
end

assert('parse_args: long flag --calibrate') do
  assert_equal true, parse_args(["--calibrate"])[:calibrate]
end

assert('parse_args: -b and --baseline both produce :baseline') do
  assert_equal 130, parse_args(["-b", "130"])[:baseline]
  assert_equal 130, parse_args(["--baseline", "130"])[:baseline]
end

assert('parse_args: -d and --duration both produce :duration') do
  assert_equal 600, parse_args(["-d", "600"])[:duration]
  assert_equal 600, parse_args(["--duration", "600"])[:duration]
end

assert('parse_args: positional COLS ROWS') do
  r = parse_args(["540", "110"])
  assert_equal 540, r[:cols]
  assert_equal 110, r[:rows]
end

assert('parse_args: only first 2 positional matter') do
  r = parse_args(["360", "90", "extra"])
  assert_equal 360, r[:cols]
  assert_equal 90, r[:rows]
end

assert('parse_args: combined flags + positionals + values') do
  r = parse_args(["-c", "540", "110", "-b", "130", "-d", "600"])
  assert_equal true, r[:calibrate]
  assert_equal 540, r[:cols]
  assert_equal 110, r[:rows]
  assert_equal 130, r[:baseline]
  assert_equal 600, r[:duration]
end

assert('parse_args: unknown switches are silently ignored') do
  r = parse_args(["--unknown", "-c", "--something"])
  assert_equal true, r[:calibrate]
end

assert('parse_args: value option without a following value is skipped') do
  r = parse_args(["-b"])
  assert_nil r[:baseline]
end
