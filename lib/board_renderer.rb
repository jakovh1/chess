# frozen_string_literal: true

require 'curses'

class BoardRenderer
  include Curses

  def initialize
    @window = Curses.stdscr
    Curses.curs_set(0)
    Curses.start_color
    Curses.init_pair(1, Curses::COLOR_BLACK, Curses::COLOR_WHITE) # Black text, white background
    Curses.init_pair(2, Curses::COLOR_WHITE, Curses::COLOR_BLACK) # black background, white text
  end

  def render(board)
    @window.clear
    draw_ranks
    draw_files
    draw_squares(board)
    @window.refresh
    sleep(10)
  end

  def close
    Curses.close_screen
  end

  private

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
      @window.setpos(8, column)
      @window.addstr(" #{c} ")
      column += 3
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
            @window.addstr(" B ")
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
            @window.addstr(" B ")
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

  def log_positions(board)
    square = board.board
    square = square.top_adjacent until square.top_adjacent.nil?
    p square.position[1]
    loop do
      if square.position[0] == 'A'
        
        loop do
          puts "#{square.position[0]} #{square.position[1]}"
          break if square.position[0] == 'H'

          square = square.right_adjacent
        end
        
      elsif square.position[0] == 'H'
        loop do
          puts "#{square.position[0]} #{square.position[1]}"
          

          square = square.left_adjacent
        end
      end
      break if square.left_adjacent.nil? && square.position == ['A', 1]
      square = square.bottom_adjacent
    end
  end
end