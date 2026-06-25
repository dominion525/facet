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
