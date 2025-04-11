# frozen_string_literal: true

module Directions
  ORTHOGONAL_DIRECTIONS = %w[top right bottom left].freeze
  DIAGONAL_DIRECTIONS = %w[top_right right_bottom bottom_left left_top].freeze

  # DIRECTION_RULES = {
  #   rook: DIRECTIONS,
  #   knight: DIRECTIONS,
  #   bishop: BISHOP_DIRECTIONS,
  #   queen: DIRECTIONS + BISHOP_DIRECTIONS,
  #   king: DIRECTIONS + BISHOP_DIRECTIONS,
  #   pawn: DIRECTIONS
  # }.freeze
end

