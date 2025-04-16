# frozen_string_literal: true

require_relative './constants/figures'

class Piece
  attr_reader :color, :name, :symbol

  def initialize(color, name)
    @color = color
    @name = name
    @symbol = PIECE_UNICODE[@color][@name]
  end
end