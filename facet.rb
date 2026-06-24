# facet - M2: page navigation
# Compile: mrbc facet.rb
# Run    : mruby -b facet.mrb
# Quit   : q + Enter

STDOUT.sync = true

CSI = "\e["

PAGES = [
  ["facet",      "", "  the minimal slide tool", "  on mruby"],
  ["page 2",     "", "  - bullet 1",             "  - bullet 2"],
  ["last page",  "", "  end"],
]

def render(idx)
  page = PAGES[idx]
  print "#{CSI}2J#{CSI}H"
  print "#{CSI}1;33m"
  puts page[0]
  print "#{CSI}0m"
  page[1..].each { |line| puts line }
  puts
  puts "  (#{idx + 1}/#{PAGES.length})  h:prev  l:next  q:quit  (then Enter)"
end

idx = 0
render(idx)

while (line = STDIN.gets)
  case line.chomp
  when "q"
    break
  when "l"
    idx += 1 if idx < PAGES.length - 1
    render(idx)
  when "h"
    idx -= 1 if idx > 0
    render(idx)
  end
end
