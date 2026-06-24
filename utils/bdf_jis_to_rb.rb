#!/usr/bin/env ruby
# Convert a Shinonome JIS X 0208 BDF (selected JIS ranges) into a
# Ruby snippet that defines `<CONST>` as a font Hash.
#
# To keep mruby's bytecode small enough to satisfy the 16-bit jump
# offset limit, the bitmaps and the UTF-8→JIS mapping are emitted as
# two long string literals (concatenated via backslash continuation,
# so they live in the literal pool as a single string each). A small
# builder function unpacks them into Hashes at runtime.
#
# Usage:
#   ruby utils/bdf_jis_to_rb.rb <font.bdf> <JIS0208.TXT> <CONST> <jis_range>...
#     jis_range: 0xHHHH-0xHHHH (both ends inclusive, JIS row/cell hex)

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

# Build packed byte arrays.
# data: for each char, 2 bytes (JIS high, JIS low) + bytes_per_char bytes of bitmap.
# u2j:  for each entry, 2 bytes Unicode + 2 bytes JIS.
data_records = chars.keys.sort.map do |jis|
  [jis >> 8, jis & 0xff, *chars[jis]]
end
u2j_records = u2j.keys.sort.map do |uni|
  jis = u2j[uni]
  [(uni >> 16) & 0xff, (uni >> 8) & 0xff, uni & 0xff, jis >> 8, jis & 0xff]
end

RECORDS_PER_CHUNK = 1000

# Emit one string literal per chunk. Each literal must stay below mrbc's
# single-string size limit (about 32 KB). Records never straddle a chunk
# boundary so the unpacker can walk a chunk linearly.
def emit_chunked(name, records, per_chunk = RECORDS_PER_CHUNK)
  chunks = records.each_slice(per_chunk).to_a
  chunks.each_with_index do |chunk, i|
    print "#{name}_#{i} = \""
    chunk.each do |bytes|
      bytes.each { |b| print "\\x%02x" % b }
    end
    puts "\""
  end
  chunks.size
end

data_const  = "#{const}_DATA"
u2j_const   = "#{const}_U2J"
builder     = "_build_#{const.downcase}"

puts "# Generated from #{File.basename(bdf_path)} (shinonome 0.9.11) + JIS0208.TXT"
puts "# Shinonome: Public Domain (Furukawa Yasuyuki, /efont/)"
puts "# JIS ranges: #{ranges.map { |r| '0x%04x-0x%04x' % [r.first, r.last] }.join(', ')}"
puts "# Chars included: #{chars.size}"
puts ""
n_data = emit_chunked(data_const, data_records)
puts ""
n_u2j  = emit_chunked(u2j_const,  u2j_records, 5000)
puts ""

data_list = (0...n_data).map { |i| "#{data_const}_#{i}" }.join(", ")
u2j_list  = (0...n_u2j ).map { |i| "#{u2j_const}_#{i}"  }.join(", ")

puts <<~RUBY
def #{builder}
  bpc = #{bytes_per_char}
  data = {}
  [#{data_list}].each do |s|
    i = 0
    len = s.bytesize
    while i < len
      jis = (s.getbyte(i) << 8) | s.getbyte(i + 1)
      data[jis] = s.byteslice(i + 2, bpc)
      i += 2 + bpc
    end
  end
  u2j = {}
  [#{u2j_list}].each do |u|
    i = 0
    len = u.bytesize
    while i < len
      uni = (u.getbyte(i) << 16) | (u.getbyte(i + 1) << 8) | u.getbyte(i + 2)
      jis = (u.getbyte(i + 3) << 8) | u.getbyte(i + 4)
      u2j[uni] = jis
      i += 5
    end
  end
  {
    width:          #{width},
    height:         #{height},
    bytes_per_row:  #{bytes_per_row},
    bytes_per_char: #{bytes_per_char},
    data: data,
    u2j:  u2j,
  }
end

#{const} = #{builder}
RUBY
