# frozen_string_literal: true

class StringDecoder
  DEBUG = false

  attr_reader :pointer, :decoded_chars

  def initialize(executable)
    @executable = executable
  end

  def self.decode_string(chars)
    builder = ""
    chars.each do |i|
      code_point = i & 0x7f
      if code_point == 0x0a || code_point == 0x0d
        builder += "\\n"
      else
        builder += code_point.chr
      end
    end
    builder
  end

  def get_decoded_string
    self.class.decode_string(@decoded_chars)
  end

  def decode_string_at(chunk, pointer)
    @chunk = chunk
    @pointer = pointer
    @lut = @executable.get_bytes(0x1bca, 92)
    @bit_queue = []
    @decoded_chars = []

    capitalize = false
    loop do
      value = shift_bits(5)
      puts format(" %02x", value) if DEBUG

      if value == 0x00
        puts if DEBUG
        return
      end

      if value == 0x1e
        capitalize = true
        next
      end

      if value > 0x1e
        value = shift_bits(6) + 0x1e
        puts format(" %02x", value - 0x1e) if DEBUG
      end

      value &= 0xff
      ascii = look_up(value)

      if capitalize && ascii >= 0xe1 && ascii <= 0xfa
        ascii &= 0xdf
      end

      capitalize = false
      @decoded_chars << ascii

      if DEBUG
        print " ("
        if ascii == 0x8a || ascii == 0x8d
          print "\\n"
        else
          print (ascii & 0x7f).chr
        end
        print ")"
      end
    end
  end

  private

  def unpack_byte
    b = @chunk.get_byte(@pointer) || 0
    @pointer += 1

    x = 0x80
    while x > 0
      @bit_queue << ((b & x) > 0)
      x >>= 1
    end
  end

  def shift_bits(len)
    raise ArgumentError if len < 1

    unpack_byte while @bit_queue.size < len

    i = 0x0
    x = 0x1 << (len - 1)

    while x > 0
      i |= x if @bit_queue.shift
      x >>= 1
    end
    i
  end

  def look_up(index)
    @lut[index - 1] & 0xff
  end
end
