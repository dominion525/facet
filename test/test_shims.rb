assert("String#bytes returns byte array") do
  assert_equal [97, 98, 99], "abc".bytes
  assert_equal [], "".bytes
  assert_equal [104, 101, 108, 108, 111, 10], "hello\n".bytes
  assert_equal [227, 129, 130], "\xE3\x81\x82".bytes
end

assert("String#start_with?") do
  assert_true "hello".start_with?("he")
  assert_false "hello".start_with?("hi")
  assert_true "hello".start_with?("hello")
  assert_false "hello".start_with?("helloo")
  assert_true "".start_with?("")
  assert_true "-foo".start_with?("-")
end

assert("String#chomp default (strip trailing newline)") do
  assert_equal "hello", "hello".chomp
  assert_equal "hello", "hello\n".chomp
  assert_equal "hello", "hello\r\n".chomp
  assert_equal "hello", "hello\r".chomp
  assert_equal "", "".chomp
  assert_equal "a\nb", "a\nb\n".chomp
end

assert("String#chomp with explicit suffix") do
  assert_equal "foo", "foobar".chomp("bar")
  assert_equal "foobar", "foobar".chomp("baz")
  assert_equal "", "".chomp("x")
end

assert("String#length on UTF-8") do
  assert_equal 0, "".length
  assert_equal 3, "abc".length
  assert_equal 1, "\xE3\x81\x82".length # "あ"
  assert_equal 3, "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86".length # "あいう"
  assert_equal 3, "a\xF0\x9F\x8D\xA3b".length # "a🍣b"
end

assert("String#empty?") do
  assert_true "".empty?
  assert_false "a".empty?
  assert_false "abc".empty?
end

assert("Array#empty?") do
  assert_true [].empty?
  assert_false [1].empty?
  assert_false [1, 2, 3].empty?
end

assert("Hash#empty?") do
  assert_true({}.empty?)
  assert_false({ a: 1 }.empty?)
end

# These asserts call the shims on literal operands on purpose.
# rubocop:disable Lint/BinaryOperatorWithIdenticalOperands, Lint/LiteralAsCondition
assert("Object#===") do
  assert_true("q" === "q")
  assert_false("q" === "l")
  assert_true(12 === 12)
  assert_false(12 === 16)
end

assert("case-when uses Object#===") do
  result = case "q"
           when "q" then "Q"
           when "l" then "L"
           else "other"
           end
  assert_equal "Q", result

  result2 = case 16
            when 12 then "k12"
            when 16 then "k16"
            end
  assert_equal "k16", result2
end

assert("Object#!=") do
  assert_true 1 != 2
  assert_false 1 != 1
  assert_true "a" != "b"
end
# rubocop:enable Lint/BinaryOperatorWithIdenticalOperands, Lint/LiteralAsCondition

assert("String#size delegates to length") do
  assert_equal 0, "".size
  assert_equal 3, "abc".size
  assert_equal 1, "\xE3\x81\x82".size
  assert_equal 3, "\xE3\x81\x82\xE3\x81\x84\xE3\x81\x86".size
end

assert("String#byteslice") do
  assert_equal "ell", "hello".byteslice(1, 3)
  assert_equal "hello", "hello".byteslice(0, 5)
  assert_equal "", "hello".byteslice(0, 0)
  assert_equal "lo", "hello".byteslice(-2, 2)
  assert_equal "", "hello".byteslice(5, 1)
  assert_nil "hello".byteslice(6, 1)
  assert_equal "l", "hello".byteslice(2)
end

assert("String#lstrip") do
  assert_equal "abc", "   abc".lstrip
  assert_equal "hi", "\t\nhi".lstrip
  assert_equal "abc", "abc".lstrip
  assert_equal "", "   ".lstrip
  assert_equal "-foo", "  -foo".lstrip
end

assert("String#to_i") do
  assert_equal 42, "42".to_i
  assert_equal(-7, "-7".to_i)
  assert_equal 3, "+3".to_i
  assert_equal 0, "0".to_i
  assert_equal 0, "".to_i
  assert_equal 100, "  100".to_i
  assert_equal 0, "abc".to_i
  assert_equal 12, "12abc".to_i
end

assert("Array#join") do
  assert_equal "abc", %w[a b c].join
  assert_equal "a-b-c", %w[a b c].join("-")
  assert_equal "", [].join
  assert_equal "only", ["only"].join("-")
end

# These asserts call the shims on literal operands on purpose.
# rubocop:disable Lint/LiteralAsCondition
assert("Object#! preserves nil/false/true specialization") do
  assert_false(!true)
  assert_true(!false)
  assert_true(!nil)
end

assert("Object#! on truthy values returns false") do
  assert_false(!0)
  assert_false(!"")
  assert_false(!"abc")
  assert_false(![])
  assert_false(!{})
  assert_false(!Object.new)
end
# rubocop:enable Lint/LiteralAsCondition
