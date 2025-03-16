# frozen_string_literal: true

require 'curses'

require_relative './lib/game'

game = Game.new
game.play

# Curses.init_screen
# begin
#   board = Board.new
#   board_renderer = BoardRenderer.new

#   board_renderer.render(board)
  
# ensure
#   Curses.close_screen
# end
# board = Board.new
# board_renderer = BoardRenderer.new

# board_renderer.render(board)