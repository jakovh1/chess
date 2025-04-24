# frozen_string_literal = true

require_relative './piece'
require_relative '../constants/directions'
require_relative '../constants/symbols'
require_relative '../modules/check_detector'

class Knight < Piece
  include Directions
  include Symbols

  include CheckDetector

  attr_accessor :left_adjacent, :right_adjacent

  def initialize(color)
    super(color, :knight)
    @left_adjacent = nil
    @right_adjacent = nil
  end

  # Generates all possible legal moves for a knight.
  # - Iterates through all possible L-shape movement directions.
  # - For each direction, calls '#knight_traversal' method which returns a 2d array with legal positions.
  # - '#flat_map' enumerable flattens the many 2d arrays into 1 2d array.
  def generate_available_positions(start_square, opponent_color, current_king)
    ORTHOGONAL_DIRECTIONS.flat_map do |direction|
      knight_traversal(start_square, direction, opponent_color, current_king)
    end
  end

  # Generates possible legal moves for a knight in a given direction.
  # - Moves 2 squares in the given direction and 1 square perpendicular.
  # - Checks if a destination square is either empty or contains opponent's piece.
  # - Adds position of the square to the result if yes.
  def knight_traversal(start_square, direction, opponent_color, current_king)
    square = start_square
    positions = []
    2.times do
      return positions if square.public_send("#{direction}_adjacent").nil?

      square = square.public_send("#{direction}_adjacent")
    end

    branches = %w[top bottom].include?(direction) ? %w[right left] : %w[top bottom]

    branches.each do |branch|
      adjacent_square = square.public_send("#{branch}_adjacent")
      if adjacent_square && (adjacent_square.current_piece.nil? ||
                            SYMBOLS[opponent_color].values.include?(adjacent_square.current_piece.symbol))
        positions.push(adjacent_square.position)
      end
    end
    filter_available_positions(positions, start_square, current_king, opponent_color)
  end
end