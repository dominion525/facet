# Pure Ruby shims for C-implemented methods.
# Each def here replaces an mruby C primitive with an equivalent Ruby
# implementation, depending only on the smallest C primitives we keep
# (bytesize / getbyte / <</[]= / each, etc).

class String
  def bytes
    result = []
    bs = bytesize
    i = 0
    while i < bs
      result << getbyte(i)
      i += 1
    end
    result
  end

  def start_with?(prefix)
    plen = prefix.bytesize
    return false if bytesize < plen

    i = 0
    while i < plen
      return false unless getbyte(i) == prefix.getbyte(i)

      i += 1
    end
    true
  end

  def chomp(suffix = nil)
    bs = bytesize
    if suffix.nil?
      return self if bs == 0

      last = getbyte(bs - 1)
      if last == 0x0A
        return byteslice(0, bs - 2) if bs >= 2 && getbyte(bs - 2) == 0x0D

        return byteslice(0, bs - 1)
      end
      return byteslice(0, bs - 1) if last == 0x0D

      self
    else
      slen = suffix.bytesize
      return self if bs < slen

      i = 0
      while i < slen
        return self unless getbyte(bs - slen + i) == suffix.getbyte(i)

        i += 1
      end
      byteslice(0, bs - slen)
    end
  end

  def length
    bs = bytesize
    n = 0
    i = 0
    while i < bs
      b = getbyte(i)
      i += if b < 0x80
             1
           elsif b < 0xE0
             2
           elsif b < 0xF0
             3
           else
             4
           end
      n += 1
    end
    n
  end
end

# NOTE: Array#length is NOT shimmed.
#   mruby's Array#each (mrblib) uses `length` internally to know the end of
#   the array, so a Pure Ruby length using each causes infinite recursion.
#   Either size or length must stay as a C primitive on the Array side.

class String
  def empty?
    bytesize == 0
  end
end

class Array
  def empty?
    size == 0
  end
end

class Hash
  def empty?
    size == 0
  end
end

class Object
  def ===(other)
    self == other
  end

  def !=(other)
    !(self == other) # rubocop:disable Style/InverseMethods -- this defines != itself
  end

  def !
    self ? false : true
  end
end

class String
  def size
    length
  end

  # One-byte strings for every byte value. `result << getbyte(i)` appends
  # the codepoint instead (0x80 and up become 2 bytes in UTF-8), so
  # byteslice appends these. Kept as 16 rows of 16: an array literal of 64
  # or more elements compiles to OP_ARRAY followed by OP_ARYPUSH.
  BYTES = [
    ["\x00", "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x0A", "\x0B", "\x0C", "\x0D", "\x0E", "\x0F"],
    ["\x10", "\x11", "\x12", "\x13", "\x14", "\x15", "\x16", "\x17", "\x18", "\x19", "\x1A", "\x1B", "\x1C", "\x1D", "\x1E", "\x1F"],
    ["\x20", "\x21", "\x22", "\x23", "\x24", "\x25", "\x26", "\x27", "\x28", "\x29", "\x2A", "\x2B", "\x2C", "\x2D", "\x2E", "\x2F"],
    ["\x30", "\x31", "\x32", "\x33", "\x34", "\x35", "\x36", "\x37", "\x38", "\x39", "\x3A", "\x3B", "\x3C", "\x3D", "\x3E", "\x3F"],
    ["\x40", "\x41", "\x42", "\x43", "\x44", "\x45", "\x46", "\x47", "\x48", "\x49", "\x4A", "\x4B", "\x4C", "\x4D", "\x4E", "\x4F"],
    ["\x50", "\x51", "\x52", "\x53", "\x54", "\x55", "\x56", "\x57", "\x58", "\x59", "\x5A", "\x5B", "\x5C", "\x5D", "\x5E", "\x5F"],
    ["\x60", "\x61", "\x62", "\x63", "\x64", "\x65", "\x66", "\x67", "\x68", "\x69", "\x6A", "\x6B", "\x6C", "\x6D", "\x6E", "\x6F"],
    ["\x70", "\x71", "\x72", "\x73", "\x74", "\x75", "\x76", "\x77", "\x78", "\x79", "\x7A", "\x7B", "\x7C", "\x7D", "\x7E", "\x7F"],
    ["\x80", "\x81", "\x82", "\x83", "\x84", "\x85", "\x86", "\x87", "\x88", "\x89", "\x8A", "\x8B", "\x8C", "\x8D", "\x8E", "\x8F"],
    ["\x90", "\x91", "\x92", "\x93", "\x94", "\x95", "\x96", "\x97", "\x98", "\x99", "\x9A", "\x9B", "\x9C", "\x9D", "\x9E", "\x9F"],
    ["\xA0", "\xA1", "\xA2", "\xA3", "\xA4", "\xA5", "\xA6", "\xA7", "\xA8", "\xA9", "\xAA", "\xAB", "\xAC", "\xAD", "\xAE", "\xAF"],
    ["\xB0", "\xB1", "\xB2", "\xB3", "\xB4", "\xB5", "\xB6", "\xB7", "\xB8", "\xB9", "\xBA", "\xBB", "\xBC", "\xBD", "\xBE", "\xBF"],
    ["\xC0", "\xC1", "\xC2", "\xC3", "\xC4", "\xC5", "\xC6", "\xC7", "\xC8", "\xC9", "\xCA", "\xCB", "\xCC", "\xCD", "\xCE", "\xCF"],
    ["\xD0", "\xD1", "\xD2", "\xD3", "\xD4", "\xD5", "\xD6", "\xD7", "\xD8", "\xD9", "\xDA", "\xDB", "\xDC", "\xDD", "\xDE", "\xDF"],
    ["\xE0", "\xE1", "\xE2", "\xE3", "\xE4", "\xE5", "\xE6", "\xE7", "\xE8", "\xE9", "\xEA", "\xEB", "\xEC", "\xED", "\xEE", "\xEF"],
    ["\xF0", "\xF1", "\xF2", "\xF3", "\xF4", "\xF5", "\xF6", "\xF7", "\xF8", "\xF9", "\xFA", "\xFB", "\xFC", "\xFD", "\xFE", "\xFF"],
  ]

  def byteslice(offset, length = 1)
    bs = bytesize
    offset += bs if offset < 0
    return nil if offset < 0 || offset > bs
    return nil if length < 0

    length = bs - offset if offset + length > bs
    result = ""
    i = 0
    while i < length
      b = getbyte(offset + i)
      result << BYTES[b >> 4][b & 15]
      i += 1
    end
    result
  end

  def lstrip
    bs = bytesize
    i = 0
    while i < bs
      b = getbyte(i)
      break unless b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x0C || b == 0x0B # rubocop:disable Style/MultipleComparison -- avoid Array#include? (C)

      i += 1
    end
    byteslice(i, bs - i)
  end

  def to_i # rubocop:disable Metrics/PerceivedComplexity
    bs = bytesize
    i = 0
    while i < bs
      b = getbyte(i)
      break unless b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D # rubocop:disable Style/MultipleComparison -- avoid Array#include? (C)

      i += 1
    end
    sign = 1
    if i < bs
      b = getbyte(i)
      if b == 0x2D
        sign = -1
        i += 1
      elsif b == 0x2B
        i += 1
      end
    end
    n = 0
    while i < bs
      b = getbyte(i)
      break if b < 0x30 || b > 0x39

      n = n * 10 + (b - 0x30)
      i += 1
    end
    n * sign
  end
end

class Array
  # facet 内の .join 呼び出しは全て String の Array に対して。
  # 非 String 要素のための to_s 呼び出しは省く。
  def join(sep = "")
    result = ""
    first = true
    each do |elem|
      result << sep unless first
      result << elem
      first = false
    end
    result
  end
end
