# frozen_string_literal: true

require_relative './lib/board'

board = Board.new
p board.board.position
p board.board.top_adjacent.position
p board.board.top_adjacent.top_adjacent.position
p board.board.top_adjacent.top_adjacent.top_right_adjacent.position
p board.board.top_adjacent.top_adjacent.top_right_adjacent.top_right_adjacent.position

