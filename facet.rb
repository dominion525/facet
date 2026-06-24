# facet - M3: alt screen, color theming, bullet decoration
# Compile: mrbc facet.rb
# Run    : mruby -b facet.mrb
# Quit   : q + Enter

STDOUT.sync = true

CSI = "\e["

COLORS = {
  reset:   "#{CSI}0m",
  bold:    "#{CSI}1m",
  dim:     "#{CSI}2m",
  red:     "#{CSI}31m",
  green:   "#{CSI}32m",
  yellow:  "#{CSI}33m",
  blue:    "#{CSI}34m",
  magenta: "#{CSI}35m",
  cyan:    "#{CSI}36m",
  white:   "#{CSI}37m",
}

PAGES = [
  { title: "facet",
    body:  ["the minimal slide tool", "on mruby"] },
  { title: "features",
    body:  ["- alt screen on enter",
            "- restores on exit",
            "- colored title and bullets"] },
  { title: "last page",
    body:  ["press q + Enter to quit"] },
]

def render_line(line)
  if line.empty?
    puts
  elsif line.start_with?("-")
    rest = line[1..].lstrip
    puts "  #{COLORS[:cyan]}•#{COLORS[:reset]} #{rest}"
  else
    puts "  #{line}"
  end
end

def render(idx)
  print "#{CSI}2J#{CSI}H"
  page = PAGES[idx]
  puts "#{COLORS[:bold]}#{COLORS[:yellow]}#{page[:title]}#{COLORS[:reset]}"
  puts
  page[:body].each { |line| render_line(line) }
  puts
  puts "#{COLORS[:dim]}(#{idx + 1}/#{PAGES.length})  h:prev  l:next  q:quit  (then Enter)#{COLORS[:reset]}"
end

begin
  print "#{CSI}?1049h"  # DECSET 1049: alt screen
  print "#{CSI}?25l"    # hide cursor

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
ensure
  print "#{CSI}?25h"    # show cursor
  print "#{CSI}?1049l"  # DECRST 1049: restore screen
end
