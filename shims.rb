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
      if b < 0x80
        i += 1
      elsif b < 0xE0
        i += 2
      elsif b < 0xF0
        i += 3
      else
        i += 4
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
    !(self == other)
  end

  def !
    self ? false : true
  end
end

class String
  def size
    length
  end

  def byteslice(offset, length = 1)
    bs = bytesize
    offset += bs if offset < 0
    return nil if offset < 0 || offset > bs
    return nil if length < 0
    length = bs - offset if offset + length > bs
    result = ""
    i = 0
    while i < length
      result << getbyte(offset + i)
      i += 1
    end
    result
  end

  def lstrip
    bs = bytesize
    i = 0
    while i < bs
      b = getbyte(i)
      break unless b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x0C || b == 0x0B
      i += 1
    end
    byteslice(i, bs - i)
  end

  def to_i
    bs = bytesize
    i = 0
    while i < bs
      b = getbyte(i)
      break unless b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D
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
