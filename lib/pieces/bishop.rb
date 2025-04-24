# frozen_string_literal: true

require_relative './piece'
require_relative '../constants/directions'
require_relative '../modules/linear_movement'

class Bishop < Piece
  include Directions
  include LinearMovement

  attr_accessor :left_adjacent, :right_adjacent

  def initialize(color)
    super(color, :bishop)
    @left_adjacent = nil
    @right_adjacent = nil
  end

  def generate_available_positions(start_square, opponent_color, current_king)
    generate_linear_moves(start_square, opponent_color, DIAGONAL_DIRECTIONS, current_king)
  end
end
