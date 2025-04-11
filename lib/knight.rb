# frozen_string_literal = true

require_relative './piece'
require_relative './constants/directions'
require_relative './constants/movement_rules'

class Knight < Piece
  include Directions

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
  def generate_available_positions(start_square, opponent_color)
    ORTHOGONAL_DIRECTIONS.flat_map do |direction|
      knight_traversal(start_square, direction, opponent_color)
    end
  end

  # Generates possible legal moves for a knight in a given direction.
  # - Moves 2 squares in the given direction and 1 square perpendicular.
  # - Checks if a destination square is either empty or contains opponent's piece.
  # - Adds position of the square to the result if yes.
  def knight_traversal(start_square, direction, opponent_color)
    positions = []
    2.times do
      return positions if start_square.public_send("#{direction}_adjacent").nil?

      start_square = start_square.public_send("#{direction}_adjacent")
    end

    branches = %w[top bottom].include?(direction) ? %w[right left] : %w[top bottom]

    branches.each do |branch|
      adjacent_square = start_square.public_send("#{branch}_adjacent")
      if adjacent_square && (adjacent_square.current_piece.nil? ||
                            Object.const_get("#{opponent_color.upcase}_FIGURES").include?(adjacent_square.current_piece.symbol))
        positions.push(adjacent_square.position)
      end
    end
    positions
  end

end