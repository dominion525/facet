#!/usr/bin/env ruby
# Convert a BDF font (ASCII range 0x20..0x7E) into a Ruby Hash literal
# for embedding in facet.rb.
#
# Usage:
#   ruby utils/bdf_to_rb.rb <font.bdf> [CONST_NAME]
#
# Output is printed to stdout.

bdf_path  = ARGV[0] or abort "usage: bdf_to_rb.rb <font.bdf> [CONST_NAME]"
const     = ARGV[1] || "FONT"
ascii     = (0x20..0x7E)

width = height = nil
chars = {}

in_bitmap = false
encoding  = nil
bitmap    = []

File.foreach(bdf_path) do |raw|
  line = raw.chomp
  if line.start_with?("FONTBOUNDINGBOX")
    parts  = line.split(/\s+/)
    width  = parts[1].to_i
    height = parts[2].to_i
  elsif line.start_with?("STARTCHAR")
    encoding = nil
    bitmap   = []
    in_bitmap = false
  elsif line.start_with?("ENCODING ")
    encoding = line.split(/\s+/)[1].to_i
  elsif line == "BITMAP"
    in_bitmap = true
  elsif line == "ENDCHAR"
    if encoding && ascii.cover?(encoding)
      chars[encoding] = bitmap.flat_map do |hex|
        hex.chars.each_slice(2).map { |s| s.join.to_i(16) }
      end
    end
    in_bitmap = false
  elsif in_bitmap
    bitmap << line
  end
end

bytes_per_row  = (width + 7) / 8
bytes_per_char = bytes_per_row * height

puts "# Generated from #{File.basename(bdf_path)} (terminus 4.49.1)"
puts "# Licensed under the SIL Open Font License, Version 1.1"
puts "# Range: 0x20..0x7E (ASCII printable)"
puts "#{const} = {"
puts "  width:          #{width},"
puts "  height:         #{height},"
puts "  bytes_per_row:  #{bytes_per_row},"
puts "  bytes_per_char: #{bytes_per_char},"
puts "  data: ["
ascii.each_with_index do |cp, i|
  rows = chars[cp] || Array.new(bytes_per_char, 0)
  esc  = rows.map { |b| "\\x%02x" % b }.join
  comma = (i == ascii.size - 1) ? "" : ","
  label = (cp == 0x20 ? "space" : cp.chr)
  puts %Q{    "#{esc}"#{comma} # 0x%02x %s} % [cp, label]
end
puts "  ].join,"
puts "}"
