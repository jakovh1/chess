# frozen_string_literal: true

require 'curses'

require_relative './lib/board'
require_relative './lib/board_renderer'

Curses.init_screen
begin
  board = Board.new
  board_renderer = BoardRenderer.new

  board_renderer.render(board)
ensure
  Curses.close_screen
end
# board = Board.new
# board_renderer = BoardRenderer.new

# board_renderer.render(board)