# frozen_string_literal: true

require_relative './piece'
require_relative './constants/movement_rules'
require_relative './constants/directions'

class Rook < Piece
  include LinearMovement
  include Directions

  attr_accessor :moved, :left_adjacent, :right_adjacent

  def initialize(color)
    super(color, :rook)
    @moved = false
    @left_adjacent = nil
    @right_adjacent = nil
  end

  def generate_available_positions(start_square, opponent_color)
    generate_linear_moves(start_square, opponent_color, ORTHOGONAL_DIRECTIONS)
  end
end