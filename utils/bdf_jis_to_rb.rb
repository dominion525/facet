#!/usr/bin/env ruby
# Convert a Shinonome JIS X 0208 BDF (selected JIS ranges) into a
# Ruby Hash literal that holds both the bitmaps and a UTF-8→JIS
# lookup. The output is meant to be prepended to facet.rb at build
# time.
#
# Usage:
#   ruby utils/bdf_jis_to_rb.rb <font.bdf> <JIS0208.TXT> <CONST> <jis_range>...
#     jis_range: 0xHHHH-0xHHHH (both ends inclusive, JIS row/cell hex)
#
# Output is printed to stdout.

bdf_path = ARGV[0] or abort "usage: bdf_jis_to_rb.rb <bdf> <jis0208.txt> <CONST> <range>..."
txt_path = ARGV[1] or abort "missing jis0208.txt"
const    = ARGV[2] or abort "missing CONST name"
range_args = ARGV[3..]
abort "no JIS ranges given" if range_args.nil? || range_args.empty?

ranges = range_args.map do |s|
  a, b = s.split('-').map { |x| Integer(x, 16) }
  (a..b)
end
allowed = ranges.flat_map(&:to_a).to_set

width = height = nil
chars = {}
encoding = nil
bitmap = []
in_bitmap = false

File.foreach(bdf_path) do |raw|
  line = raw.chomp
  if line.start_with?("FONTBOUNDINGBOX")
    parts = line.split(/\s+/)
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
    if encoding && allowed.include?(encoding)
      chars[encoding] = bitmap.flat_map do |hex|
        hex.chars.each_slice(2).map { |s| s.join.to_i(16) }
      end
    end
    in_bitmap = false
  elsif in_bitmap
    bitmap << line
  end
end

u2j = {}
File.foreach(txt_path) do |line|
  next if line.start_with?("#")
  cols = line.split(/\s+/)
  next if cols.size < 3
  jis_str = cols[1]
  uni_str = cols[2]
  next if jis_str == "" || uni_str == ""
  jis = Integer(jis_str, 16)
  uni = Integer(uni_str, 16)
  u2j[uni] = jis if chars.key?(jis)
end

bytes_per_row  = (width + 7) / 8
bytes_per_char = bytes_per_row * height

puts "# Generated from #{File.basename(bdf_path)} (shinonome 0.9.11) + JIS0208.TXT"
puts "# Shinonome: Public Domain (Furukawa Yasuyuki, /efont/)"
puts "# JIS ranges: #{ranges.map { |r| '0x%04x-0x%04x' % [r.first, r.last] }.join(', ')}"
puts "# Chars included: #{chars.size}"
puts "#{const} = {"
puts "  width:          #{width},"
puts "  height:         #{height},"
puts "  bytes_per_row:  #{bytes_per_row},"
puts "  bytes_per_char: #{bytes_per_char},"
puts "  data: {"
chars.keys.sort.each do |jis|
  esc = chars[jis].map { |b| "\\x%02x" % b }.join
  puts %Q{    0x%04x => "#{esc}",} % jis
end
puts "  },"
puts "  u2j: {"
u2j.keys.sort.each do |uni|
  puts "    0x%04x => 0x%04x," % [uni, u2j[uni]]
end
puts "  },"
puts "}"
