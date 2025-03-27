# frozen_string_literal: true

class Square
  attr_accessor :color, :position, :current_piece, :top_adjacent, :top_right_adjacent, :right_adjacent, :right_bottom_adjacent, :bottom_adjacent, :bottom_left_adjacent, :left_adjacent, :left_top_adjacent, :movable

  def initialize(color, position, piece = nil, top_adjacent = nil, top_right_adjacent = nil, right_adjacent = nil, right_bottom_adjacent = nil, bottom_adjacent = nil, bottom_left_adjacent = nil, left_adjacent = nil, left_top_adjacent = nil)
    @color = color
    @position = position
    @current_piece = piece
    @top_adjacent = top_adjacent
    @top_right_adjacent = top_right_adjacent
    @right_adjacent = right_adjacent
    @right_bottom_adjacent = right_bottom_adjacent
    @bottom_adjacent = bottom_adjacent
    @bottom_left_adjacent = bottom_left_adjacent
    @left_adjacent = left_adjacent
    @left_top_adjacent = left_top_adjacent
  end
end