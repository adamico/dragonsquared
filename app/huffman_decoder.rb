# frozen_string_literal: true

class HuffmanDecoder
  class HuffmanNode; end

  class HuffmanTree < HuffmanNode
    attr_reader :left, :right
    def initialize(left, right)
      @left = left
      @right = right
    end
  end

  class HuffmanLeaf < HuffmanNode
    attr_reader :value
    def initialize(value)
      @value = value
    end
  end

  Trace = Struct.new(:run, :word)

  def initialize(chunk)
    @chunk = chunk
    @chunk_pointer = 0
    @chunk_size = 0
    @traces = []
    @bit_buffer = []
    @trace_index = 0
  end

  def decode
    @chunk_pointer = 0
    @chunk_size = get_chunk_word

    @traces = []
    @bit_buffer = []
    @trace_index = 0

    root = build_huffman_tree(0)
    tree_decode(root)
  end

  def decode_chunk
    Chunk.new(decode)
  end

  private

  def build_huffman_tree(run)
    if run == run_length
      value = data_word
      next_trace
      return HuffmanLeaf.new(value)
    end

    left = build_huffman_tree(run + 1)
    right = build_huffman_tree(0)
    HuffmanTree.new(left, right)
  end

  def tree_decode(tree_root)
    decoded = []
    count = @chunk_size
    node = tree_root

    while count > 0
      if node.is_a?(HuffmanLeaf)
        decoded << (node.value & 0xff)
        node = tree_root
        count -= 1
        next
      end

      unpack_byte if @bit_buffer.empty?
      next_bit = @bit_buffer.shift

      if node.is_a?(HuffmanTree)
        node = next_bit ? node.right : node.left
      else
        raise "Expected node to be a HuffmanTree"
      end
    end

    decoded
  end

  def get_chunk_byte
    b = @chunk.get_byte(@chunk_pointer)
    @chunk_pointer += 1
    b || 0
  end

  def get_chunk_word
    word = @chunk.get_word(@chunk_pointer)
    @chunk_pointer += 2
    word || 0
  end

  def get_trace
    read_next_trace while @trace_index >= @traces.size
    @traces[@trace_index]
  end

  def next_trace
    @trace_index += 1
  end

  def run_length
    get_trace.run
  end

  def data_word
    get_trace.word
  end

  def read_next_trace
    zero_count = -1
    next_bit = false

    begin
      zero_count += 1
      unpack_byte if @bit_buffer.empty?
      next_bit = @bit_buffer.shift
    end until next_bit

    @traces << Trace.new(zero_count, parse_int_from_bits)
  end

  def unpack_byte
    b = get_chunk_byte
    x = 0x80
    while x > 0
      @bit_buffer << ((b & x) > 0)
      x >>= 1
    end
  end

  def parse_int_from_bits
    unpack_byte while @bit_buffer.size < 8

    i = 0x0
    x = 0x80
    while x > 0
      i |= x if @bit_buffer.shift
      x >>= 1
    end
    i
  end
end
