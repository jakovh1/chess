# frozen_string_literal: true

require_relative './constants/symbols'

class Piece
  include Symbols
  attr_reader :color, :name, :symbol

  def initialize(color, name)
    @color = color
    @name = name
    @symbol = SYMBOLS[@color][@name]
  end
end