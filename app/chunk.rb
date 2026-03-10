# frozen_string_literal: true

class Chunk
  attr_reader :raw

  def initialize(raw_bytes)
    @raw = raw_bytes.dup
  end

  def get_byte(i)
    return 0 if i < 0 || i >= size
    @raw[i]
  end

  def get_bytes(offset, length)
    end_idx = offset + length
    end_idx = size if end_idx > size
    return [] if offset > end_idx
    @raw[offset...end_idx]
  end

  def size
    @raw.size
  end

  def get_unsigned_byte(i)
    return 0 if i < 0 || i >= size
    @raw[i] & 0xff
  end

  def get_word(i)
    b0 = get_unsigned_byte(i)
    b1 = get_unsigned_byte(i + 1)
    (b1 << 8) | b0
  end

  def get_quad_word(i)
    b0 = get_unsigned_byte(i)
    b1 = get_unsigned_byte(i + 1)
    b2 = get_unsigned_byte(i + 2)
    b3 = get_unsigned_byte(i + 3)
    (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
  end

  def read(offset, num)
    raise ArgumentError, "Can't read more bytes than fit in an int (4)" if num > 4
    value = 0
    (num - 1).downto(0) do |i|
      value = value << 8
      value = value | get_unsigned_byte(i + offset)
    end
    value
  end

  def empty?
    @raw.empty?
  end
end

class ModifiableChunk < Chunk
  attr_reader :dirty
  alias is_dirty? dirty

  def initialize(raw_bytes)
    super
    @dirty = false
  end

  def clean!
    @dirty = false
  end

  def write(index, length, value)
    v = value
    length.times do |i|
      new_value = v & 0xff
      if @raw[index + i] != new_value
        @raw[index + i] = new_value
        @dirty = true
      end
      v >>= 8
    end
  end

  def set_bytes(index, values)
    values.each_with_index do |b, i|
      new_value = b & 0xff
      if @raw[index + i] != new_value
        @raw[index + i] = new_value
        @dirty = true
      end
    end
  end
end
