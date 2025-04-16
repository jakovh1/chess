# frozen_string_literal: true

require_relative './piece'
require_relative './constants/directions'
require_relative './constants/movement_rules'

class Queen < Piece
  include Directions
  include LinearMovement

  attr_accessor :left_adjacent, :right_adjacent

  def initialize(color)
    super(color, :queen)
    @left_adjacent = nil
    @right_adjacent = nil
  end

  def generate_available_positions(start_square, opponent_color)
    generate_linear_moves(start_square, opponent_color, DIAGONAL_DIRECTIONS + ORTHOGONAL_DIRECTIONS)
  end
end