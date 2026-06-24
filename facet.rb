# facet - M1: minimal one-page slide
# Compile: mrbc facet.rb
# Run    : mruby -b facet.mrb
# Quit   : Ctrl+C

STDOUT.sync = true

CSI = "\e["

def reset
  print "#{CSI}0m"
end

print "#{CSI}2J#{CSI}H"

print "#{CSI}1;33m"
puts "facet"
reset

puts
puts

print "#{CSI}36m"
puts "  the minimal slide tool"
puts "  on mruby"
reset

puts
puts "  (Ctrl+C to quit)"

loop { sleep 1 }
