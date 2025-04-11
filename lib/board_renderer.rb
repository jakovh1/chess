# frozen_string_literal: true

require 'curses'
require_relative './constants/figures'

class BoardRenderer
  include Curses

  def initialize
    @window = Curses.stdscr

    Curses.start_color
    Curses.use_default_colors

    Curses.init_color(3, 600, 600, 100) # color for black square
    Curses.init_color(4, 900, 500, 200) # background color for available position square

    Curses.init_pair(1, COLOR_BLACK, COLOR_WHITE) # white square
    Curses.init_pair(2, COLOR_BLACK, 3) # black square
    Curses.init_pair(3, COLOR_BLACK, COLOR_CYAN) # cursor square
    Curses.init_pair(5, COLOR_BLACK, 4) # available position square pair
  end

  def render(board, current_player, available_positions = nil, message = nil)
    @window.clear
    show_current_player(current_player)
    draw_ranks
    draw_files
    draw_squares(board)
    highlight_available_positions(available_positions) if available_positions
    show_message(message) if message
    show_captured_pieces(board) if board.white_captured_pieces || board.black_captured_pieces
    draw_cursor(board)
    @window.refresh
  end

  def close
    Curses.close_screen
  end

  private

  def show_current_player(color)
    Curses.setpos(0, 0)
    Curses.curs_set(1)
    Curses.addstr("#{color} player has the move.")
  end

  def draw_cursor(board)
    Curses.curs_set(2)
    Curses.attron(Curses.color_pair(3)) do
      Curses.setpos(board.cursor_y, board.cursor_x)
      if ![1, 11].include?(board.cursor_y)
        Curses.addstr(" #{board.current_square&.current_piece&.symbol || ' '} ")
      elsif board.cursor_y == 1
        Curses.addstr(" #{board.current_white_captured_piece.symbol || ' '} ")
      elsif board.cursor_y == 11
        Curses.addstr(" #{board.current_black_captured_piece.symbol || ' '} ")
      end
    end
    Curses.setpos(board.cursor_y, board.cursor_x)
    Curses.curs_set(0)
  end

  def draw_ranks
    8.downto(1) do |c|
      row = (c != 8 ? ((c % 8) - 8) * -1 : 0) + 2
      @window.setpos(row, 0)
      @window.addstr(c.to_s)
    end
  end

  def draw_files
    column = 2
    'A'.upto('H') do |c|
      @window.setpos(10, column)
      @window.addstr(" #{c} ")
      column += 3
    end
  end

  def show_message(message)
    @window.setpos(13, 2)
    @window.addstr(message)
  end

  def show_captured_pieces(board)
    col = 3
    
    current_piece = board.white_captured_pieces
    until current_piece.nil?
      @window.setpos(1, col)
      @window.addstr(current_piece.symbol)
      current_piece = current_piece.right_adjacent
      col += 3
    end
    col = 3
   
    current_piece = board.black_captured_pieces
    while current_piece
      @window.setpos(11, col)
      @window.addstr(current_piece.symbol)
      current_piece = current_piece.right_adjacent
      col += 3
    end
  end

  def draw_squares(board)
    square = board.board
    square = square.top_adjacent until square.top_adjacent.nil?
    @window.setpos(0, 1)

    loop do

      if square.position[0] == 'A'
        column = 2
        loop do

          row = 10 - square.position[1]
          color = square.color == 'black' ? 2 : 1
          @window.setpos(row, column)
          @window.attron(Curses.color_pair(color)) do
            @window.addstr(" #{square.current_piece&.symbol || ' '} ")
          end
          column += 3
          break if square.position[0] == 'H'

          square = square.right_adjacent
        end
      elsif square.position[0] == 'H'
        column = 23
        loop do

          row = 10 - square.position[1]
          color = square.color == 'black' ? 2 : 1
          @window.setpos(row, column)
          @window.attron(Curses.color_pair(color)) do
            @window.addstr(" #{square.current_piece&.symbol || ' '} ")
          end
          column -= 3
          break if square.position[0] == 'A'

          square = square.left_adjacent
        end
      end
      break if square.position == ['A', 1]

      square = square.bottom_adjacent
    end
  end

  # Highlights available positions if there are any when a piece is selected.
  def highlight_available_positions(available_positions)
    available_positions.each do |position|
      position = translate_position(position)
      @window.setpos(position[1], position[0])
      @window.attron(Curses.color_pair(5)) do
        @window.addstr(' ')
      end
    end
    @window.attroff(Curses.color_pair(5))
  end

  # Translates chess-board files and ranks to Curses cursor's coordinates.
  def translate_position(position)
    [3 * position[0].ord - 193, -2 * position[1] + 10 + position[1]]
  end

  # def log_positions(board)
  #   square = board.board
  #   square = square.top_adjacent until square.top_adjacent.nil?
  #   p square.position[1]
  #   loop do
  #     if square.position[0] == 'A'
        
  #       loop do
  #         puts "#{square.position[0]} #{square.position[1]}"
  #         break if square.position[0] == 'H'

  #         square = square.right_adjacent
  #       end
        
  #     elsif square.position[0] == 'H'
  #       loop do
  #         puts "#{square.position[0]} #{square.position[1]}"
        

  #         square = square.left_adjacent
  #       end
  #     end
  #     break if square.left_adjacent.nil? && square.position == ['A', 1]
  #     square = square.bottom_adjacent
  #   end
  # end
end