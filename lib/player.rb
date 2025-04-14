# frozen_string_literal: true

class Player
  attr_accessor :captured_pieces, :active_squares, :a_rook_moved, :h_rook_moved, :recently_moved_pawn
  attr_reader :color

  def initialize(color)
    @color = color
    @captured_pieces = nil
    @active_squares = {
      rook: [],
      knight: [],
      bishop: [],
      pawn: [],
      queen: [],
      king: []
    }
    @recently_moved_pawn = nil
    @a_rook_moved = false
    @h_rook_moved = false
  end

end