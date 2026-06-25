# Smoke test: confirm the assert.rb + driver.rb pipeline works at all.

assert('smoke: integer math') do
  assert_equal 2, 1 + 1
  assert_equal 6, 2 * 3
end

assert('smoke: string concat') do
  assert_equal "ab", "a" + "b"
end

assert('smoke: array op') do
  assert_equal [1, 2, 3], [1, 2] + [3]
end
