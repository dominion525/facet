#!/usr/bin/env ruby
# Repack fonts/terminus_*.rb into a single-string-literal form to reduce
# the mrbc literal-pool footprint (95 literals -> 1 literal per size).
# Runs under CRuby; reads the existing FONT_* Hash, then rewrites the .rb.

sizes = [
  ["FONT_6x12",  "fonts/terminus_6x12.rb"],
  ["FONT_8x16",  "fonts/terminus_8x16.rb"],
  ["FONT_12x24", "fonts/terminus_12x24.rb"],
  ["FONT_16x32", "fonts/terminus_16x32.rb"],
]

sizes.each do |const, path|
  load "./#{path}"
  font = Object.const_get(const)
  esc  = font[:data].bytes.map { |b| "\\x%02x" % b }.join

  File.write(path, <<~RUBY)
    # Generated from terminus BDF (4.49.1)
    # Licensed under the SIL Open Font License, Version 1.1
    # Range: 0x20..0x7E (ASCII printable)
    # Data layout: 95 chars * #{font[:bytes_per_char]} bytes each, ordered cp 0x20..0x7E
    #{const} = {
      width:          #{font[:width]},
      height:         #{font[:height]},
      bytes_per_row:  #{font[:bytes_per_row]},
      bytes_per_char: #{font[:bytes_per_char]},
      data: "#{esc}",
    }
  RUBY
  puts "rewrote #{path} (#{font[:data].bytesize} byte data, 1 literal)"
end
