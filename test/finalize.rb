# Called last in the test bundle. report() is defined in assert.rb and
# returns true when there were no failures.
ok = report
exit(ok ? 0 : 1)
