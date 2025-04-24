# frozen_string_liberal: true

module GameSaver
  def to_marshal(board, selected_piece, old_square, available_positions, white_player, black_player, current_player, inactive_player, current_king, message)
    Marshal.dump({
      board: board,
      selected_piece: selected_piece,
      old_square: old_square,
      available_positions: available_positions,
      white_player: white_player,
      black_player: black_player,
      current_player: current_player,
      inactive_player: inactive_player,
      current_king: current_king,
      message: message
      })
  end

  def save_game(board, selected_piece, old_square, available_positions, white_player, black_player, current_player, inactive_player, current_king, message)
    begin
      data = to_marshal(board, selected_piece, old_square, available_positions, white_player, black_player, current_player, inactive_player, current_king, message)
      current_datetime = Time.now.strftime('%Y-%m-%d_%H:%M:%S')
      filename = "./lib/saves/#{current_datetime}.marshal"
      File.binwrite(filename, data)
      File.exist?(filename)
    rescue StandardError => e
      puts "Save game failed: #{e.message}"
      false
    end
  end


end