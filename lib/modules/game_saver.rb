# frozen_string_liberal: true

require 'json'

module Serializer
  
  def dump_to_json(board, selected_piece, old_square, available_positions, white_player, black_player, current_player, inactive_player, current_king, message)
    JSON.dump ({
      :board => board,
      selected_piece: selected_piece
    })
  end

end