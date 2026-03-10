# Your main DRGTK logic will go here
require 'app/chunk.rb'
require 'app/chunk_table.rb'
require 'app/huffman_decoder.rb'
require 'app/string_decoder.rb'
require 'app/load_data_task.rb'

def tick args
  # Initialize the task once
  args.state.load_task ||= LoadDataTask.new

  # Perform a slice of loading work per tick to avoid locking up the DRGTK engine
  args.state.load_task.tick(args)

  # Display the status of loading on screen
  args.outputs.labels << [10, 710, args.state.load_task.status_message]
end
