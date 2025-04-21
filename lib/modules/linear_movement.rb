# frozen_string_literal: true

require_relative '../constants/symbols'

require_relative './check_detector'
module LinearMovement
  include CheckDetector
  include Symbols
  # Generates all possible legal moves for rooks, bishops and queens.
  # - Iterates through all linear (sliding) movement directions.
  # - For each direction, calls '#linear_traversal' method which returns a 2d array with legal positions.
  # - '#flat_map' enumerable flattens the many 2d arrays into 1 2d array.
  def generate_linear_moves(start_square, opponent_color, directions, current_king)
    directions.flat_map do |direction|
      linear_traversal(start_square, direction, opponent_color, current_king)
    end
  end

  # Generates all possible squares (positions) for the given direction.
  # - Traverses in a given direction and adds position of the square to the result array
  # - if the square is empty or occupied by the opponent's piece.
  def linear_traversal(start_square, direction, opponent_color, current_king)
    square = start_square

    positions = []
    loop do
      break if square.public_send("#{direction}_adjacent").nil?

      if square.public_send("#{direction}_adjacent")&.current_piece.nil?
        positions.push(square.public_send("#{direction}_adjacent").position)
        square = square.public_send("#{direction}_adjacent")
      elsif SYMBOLS[opponent_color].values.include?(square.public_send("#{direction}_adjacent").current_piece.symbol)
        positions.push(square.public_send("#{direction}_adjacent").position)
        break
      else
        break
      end
    end
    filter_available_positions(positions, start_square, current_king, opponent_color)
  end
end