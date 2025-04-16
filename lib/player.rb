# frozen_string_literal: true

class Player
  attr_accessor :active_squares, :recently_moved_pawn
  attr_reader :color

  def initialize(color)
    @color = color
    @active_squares = {
      rook: [],
      knight: [],
      bishop: [],
      pawn: [],
      queen: [],
      king: []
    }
    @recently_moved_pawn = nil
  end
end