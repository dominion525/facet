# Standalone test driver for use with vendored test/assert.rb.
#
# The official mrbtest pipeline lives in mruby's mrbgems/mruby-test/driver.c
# (a C binary built with `make test`). We are running on the plain Homebrew
# mruby, so we provide the same hooks (`t_print` and a `report`-call + exit
# at the end) directly in Ruby. assert.rb itself already initializes all
# the `$ok_test` / `$ko_test` / ... globals at load time.

def t_print(*args)
  args.each { |a| print(a.to_s) }
  nil
end
