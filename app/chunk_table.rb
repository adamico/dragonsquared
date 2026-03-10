# frozen_string_literal: true
require 'app/chunk.rb'

class ChunkTable
  TITLE_SCREEN = 0x1d
  YOU_WIN = 0x18
  SKY_TEXTURE = 0x6f

  FilePointer = Struct.new(:file_num, :start, :size)

  attr_reader :data1_chunks, :data2_chunks

  def initialize(data1_path, data2_path)
    @data1_path = data1_path
    @data2_path = data2_path
    @data1_chunks = read_file_table(data1_path, 1)
    @data2_chunks = read_file_table(data2_path, 2)
  end

  def get_chunk_count
    @data1_chunks.size
  end

  def read_chunk(chunk_id)
    Chunk.new(read_chunk_helper(chunk_id))
  end

  def get_modifiable_chunk(chunk_id)
    ModifiableChunk.new(read_chunk_helper(chunk_id))
  end

  private

  def get_pointer(chunk_id)
    fp1 = @data1_chunks[chunk_id]
    fp2 = @data2_chunks[chunk_id]

    if fp1.nil? || fp1.start == 0x00
      if fp2.nil? || fp2.start == 0x00
        return nil
      else
        return fp2
      end
    else
      return fp1
    end
  end

  def read_chunk_helper(chunk_id)
    fp = get_pointer(chunk_id)
    return [] if fp.nil?

    path = fp.file_num == 1 ? @data1_path : @data2_path

    # In DragonRuby, file operations are usually handled by $gtk.read_file which returns a string
    # Since we need binary data, we'll unpack it.
    # Note: If $gtk.read_file gets too slow for large chunks, we might need C extensions,
    # but for typical 90s game chunks it should be fine.

    file_contents = $gtk.read_file(path)
    return [] unless file_contents

    chunk_data = file_contents.byteslice(fp.start, fp.size)
    return [] unless chunk_data

    chunk_data.bytes
  end

  def read_file_table(path, file_num)
    chunks = []

    file_contents = $gtk.read_file(path)
    return chunks unless file_contents

    next_pointer = 0x300

    (0...0x300).step(2) do |pointer|
      b0 = file_contents.getbyte(pointer)
      b1 = file_contents.getbyte(pointer + 1)
      break if b0.nil? || b1.nil?

      size = (b1 << 8) | b0

      if size == 0 || (size & 0x8000) > 0
        chunks << nil
      else
        chunks << FilePointer.new(file_num, next_pointer, size)
        next_pointer += size
      end
    end

    chunks
  end
end
