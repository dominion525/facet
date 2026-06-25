# Output-capture helper for render tests.
#
# Redefines top-level `print` and `puts` so that, when called from inside
# a `capture { ... }` block, their arguments are accumulated into
# `$capture_buf` instead of being written to stdout. Outside `capture`
# the helpers fall back to `STDOUT.write` so normal output (used by the
# driver and by assert.rb's `t_print`) still works.

$capture_buf = nil

def capture
  prev = $capture_buf
  $capture_buf = ""
  yield
  result = $capture_buf
  $capture_buf = prev
  result
end

def print(*args)
  if $capture_buf
    args.each { |a| $capture_buf << a.to_s }
  else
    args.each { |a| STDOUT.write(a.to_s) }
  end
  nil
end

def puts(*args)
  if $capture_buf
    if args.empty?
      $capture_buf << "\n"
    else
      args.each do |a|
        s = a.to_s
        $capture_buf << s
        $capture_buf << "\n" unless s.end_with?("\n")
      end
    end
  elsif args.empty?
    STDOUT.write("\n")
  else
    args.each do |a|
      s = a.to_s
      STDOUT.write(s)
      STDOUT.write("\n") unless s.end_with?("\n")
    end
  end
  nil
end
