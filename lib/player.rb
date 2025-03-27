# frozen_string_literal: true

class Player
  attr_accessor :color, :captured_pieces, :active_squares

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
  end
end