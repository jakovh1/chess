# frozen_string_literal: true

require_relative './piece'
require_relative './modules/linear_movement'
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

  def generate_available_positions(start_square, opponent_color, current_king)
    generate_linear_moves(start_square, opponent_color, ORTHOGONAL_DIRECTIONS, current_king)
  end
end