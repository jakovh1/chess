# frozen_string_literal: true

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
    draw_ranks
    draw_files
    draw_squares(board.board)
    highlight_available_positions(available_positions) if available_positions
    show_text(message, current_player)
    show_captured_pieces(board.white_captured_pieces, 1) if board.white_captured_pieces
    show_captured_pieces(board.black_captured_pieces, 11) if board.black_captured_pieces
    draw_cursor(board)
    @window.refresh
  end

  def render_load_menu(saves, current_row)
    saves_length = saves.length
    Curses.curs_set(0)
    @window.clear
    saves.each_with_index do |filename, index|
      if current_row == index
        attron(color_pair(1) | A_BOLD) do
          @window.setpos(index, 0)
          @window.addstr("#{index + 1} #{filename[0..-9]}")
        end
      else
        @window.setpos(index, 0)
        @window.addstr("#{index + 1} #{filename[0..-9]}")
      end
    end
    @window.setpos(saves_length + 1, 0)
    @window.addstr('Select the game you want to load. (↑, ↓, ↵).')
    @window.refresh
  end

  private

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

  def show_text(message, color)
    @window.setpos(0, 0)
    Curses.curs_set(1)
    @window.addstr("#{color} player has the move.")
    return unless message

    @window.setpos(13, 2)
    @window.addstr(message)
  end

  def show_captured_pieces(captured_pieces, row)
    col = 3
    captured_piece = captured_pieces
    until captured_piece.nil?
      @window.setpos(row, col)
      @window.addstr(captured_piece.symbol)
      captured_piece = captured_piece.right_adjacent
      col += 3
    end
  end

  def draw_squares(bottom_square)
    square = bottom_square
    square = square.top_adjacent until square.top_adjacent.nil?
    @window.setpos(0, 1)

    loop do
      square = draw_square_row(square)
      break if square.position == ['A', 1]

      square = square.bottom_adjacent
    end
  end

  def draw_square_row(square)
    column, next_square, last_square_file, column_offset = square.position[0] == 'A' ? [2, :right_adjacent, 'H', 3] : [23, :left_adjacent, 'A', -3]
    loop do
      draw_square(square, column)
      column += column_offset
      break if square.position[0] == last_square_file

      square = square.send(next_square)
    end
    square
  end

  def draw_square(square, column)
    row = 10 - square.position[1]
    color = square.color == 'black' ? 2 : 1
    @window.setpos(row, column)
    @window.attron(Curses.color_pair(color)) do
      @window.addstr(" #{square.current_piece&.symbol || ' '} ")
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
end