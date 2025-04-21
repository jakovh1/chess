# frozen_string_literal: true

module DrawDetector
  def stalemate?(active_squares, opponent_color, current_king)
    active_squares.each_value do |squares|
      squares.each do |square|
        return false unless square.current_piece.generate_available_positions(square, opponent_color, current_king).empty?
      end
    end
    true
  end

  def insufficient_material?(current_player, inactive_player)
    active_player_pieces = get_active_pieces(current_player)
    inactive_player_pieces = get_active_pieces(inactive_player)

    active_sum = active_player_pieces.values.map(&:length).sum
    inactive_sum = inactive_player_pieces.values.map(&:length).sum

    return false if active_sum > 2 || inactive_sum > 2

    return true if king_v_king?(active_sum, inactive_sum)

    return true if king_v_two?(active_player_pieces, inactive_player_pieces, :bishop, active_sum, inactive_sum)

    return true if king_v_two?(active_player_pieces, inactive_player_pieces, :knight, active_sum, inactive_sum)

    return true if king_bishop_v_king_bishop?(active_player_pieces, inactive_player_pieces, active_sum, inactive_sum)

    false
  end

  def king_v_king?(active_sum, inactive_sum)
    active_sum == 1 && inactive_sum == 1
  end

  def king_v_two?(active_player_pieces, inactive_player_pieces, piece, active_sum, inactive_sum)
    return false unless active_sum + inactive_sum == 3

    inactive_player_pieces.key?(piece) || active_player_pieces.key?(piece)
  end

  def king_bishop_v_king_bishop?(active_player_pieces, inactive_player_pieces, active_sum, inactive_sum)
    return false unless active_sum == 2 && inactive_sum == 2

    return false unless active_player_pieces.key?(:bishop) && inactive_player_pieces.key?(:bishop)

    active_player_pieces[:bishop].first.color == inactive_player_pieces[:bishop].first.color
  end

  def get_active_pieces(player)
    result = {}

    player.active_squares.each do |piece, squares|
      result[piece] = squares unless squares.empty?
    end
    result
  end
end