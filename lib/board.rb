# frozen_string_literal: true

require_relative './square'

class Board
  attr_reader :board
  def initialize()
    @board = Square.new('black', ['A', 1], nil, nil, nil, nil, nil, nil, nil, nil, nil)
    generate_board(@board)
  end

  private

  def generate_board(square)
    last_square = square
    last_square = generate_row(last_square) until last_square.position == ['A', 8]
    last_square = establish_relationships(last_square) until last_square.position == ['A', 1]
  end

  def toggle_color(square)
    return 'white' if square.color == 'black'

    'black'
  end

  def generate_row(square)
    current_square = square
    if current_square.position[0] == 'A'

      unless current_square.right_adjacent.nil?
        current_square.top_adjacent = Square.new(toggle_color(current_square), [current_square.position[0], current_square.position[1] + 1])
        current_square.top_adjacent.bottom_adjacent = current_square
        current_square = current_square.top_adjacent
      end

      until current_square.position[0] == 'H'
        current_square.right_adjacent = Square.new(toggle_color(current_square), [(current_square.position[0].ord + 1).chr, current_square.position[1]])
        current_square.right_adjacent.left_adjacent = current_square
        current_square = current_square.right_adjacent
      end

    elsif current_square.position[0] == 'H' && !current_square.left_adjacent.nil?

      current_square.top_adjacent = Square.new(toggle_color(current_square), [current_square.position[0], current_square.position[1] + 1])
      current_square.top_adjacent.bottom_adjacent = current_square
      current_square = current_square.top_adjacent

      until current_square.position[0] == 'A'
        current_square.left_adjacent = Square.new(toggle_color(current_square), [(current_square.position[0].ord - 1).chr, current_square.position[1]])
        current_square.left_adjacent.right_adjacent = current_square
        current_square = current_square.left_adjacent
      end
    end

    current_square
  end

  def establish_relationships(square)
    if square.position[1] == 8
      square = square.right_adjacent until square.right_adjacent.nil?
    end

    second_square = square.bottom_adjacent

    if second_square.position[0] == 'H'

      until second_square.position[0] == 'A'
        second_square.left_top_adjacent = square.left_adjacent
        square.left_adjacent.right_bottom_adjacent = second_square

        second_square.left_adjacent.top_right_adjacent = square
        square.bottom_left_adjacent = second_square.left_adjacent

        second_square.left_adjacent.top_adjacent = square.left_adjacent
        square.left_adjacent.bottom_adjacent = second_square.left_adjacent

        square = square.left_adjacent
        second_square = second_square.left_adjacent

      end

    elsif second_square.position[0] == 'A'

      until second_square.position[0] == 'H'
        second_square.top_right_adjacent = square.right_adjacent
        square.right_adjacent.bottom_left_adjacent = second_square

        second_square.right_adjacent.left_top_adjacent = square
        square.right_bottom_adjacent = second_square.right_adjacent

        second_square.right_adjacent.top_adjacent = square.right_adjacent
        square.right_adjacent.bottom_adjacent = second_square.right_adjacent

        square = square.right_adjacent
        second_square = second_square.right_adjacent
      end

    end

    second_square

  end
end