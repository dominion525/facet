# Standalone test driver for use with vendored test/assert.rb.
#
# The official mrbtest pipeline lives in mruby's mrbgems/mruby-test/driver.c
# (a C binary built with `make test`). We are running on the plain Homebrew
# mruby, so we provide the same hooks (`t_print` and a `report`-call + exit
# at the end) directly in Ruby. assert.rb itself already initializes all
# the `$ok_test` / `$ko_test` / ... globals at load time.

def t_print(*args)
  # Use STDOUT.write directly so that test/helper.rb redefining `print`
  # for output capture cannot accidentally swallow the test result.
  args.each { |a| STDOUT.write(a.to_s) }
  nil
end
