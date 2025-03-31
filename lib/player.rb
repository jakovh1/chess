# frozen_string_literal: true

class Player
  attr_accessor :color, :captured_pieces, :active_squares, :a_rook_moved, :h_rook_moved

  def initialize(color)
    @color = color
    @captured_pieces = []
    @active_squares = {
      rook: [],
      knight: [],
      bishop: [],
      pawn: [],
      queen: [],
      king: []
    }
    @a_rook_moved = false
    @h_rook_moved = false
  end
end