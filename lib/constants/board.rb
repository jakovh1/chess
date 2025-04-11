# frozen_string_literal: true

require_relative './square'
require_relative './piece'
require_relative './constants/figures'

class Board
  attr_accessor :board, :cursor_x, :cursor_y, :current_square

  def initialize(white_player, black_player)
    @board = Square.new('black', ['A', 1], nil, nil, nil, nil, nil, nil, nil, nil, nil)
    @cursor_x = 2
    @cursor_y = 9
    @current_square = @board
    generate_board(@board, white_player, black_player)
  end

  private

  def generate_board(square, white_player, black_player)
    last_square = square
    last_square = generate_row(last_square) until last_square.position == ['A', 8]
    last_square = establish_relationships(last_square) until last_square.position == ['A', 1]
    place_pieces(last_square, white_player, black_player)
  end

  # toggles the square background color
  def toggle_color(square)
    return 'white' if square.color == 'black'

    'black'
  end

  # generates squares (nodes) in a row, returns the latest generated
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
    # establishes relationships from the most-right square to the most-left square
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
    # establishes relationships from the most-right square to the most-left square
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

  # Traverse through the board and place pieces onto their inital posiitons.
  def place_pieces(square, white_player, black_player)
    loop do
      case square.position[1]
      # 1 and 2 cases (ranks) place white pieces
      when 1
        if %w[A H].include?(square.position[0])
          square.current_piece = Piece.new(:White, :rook)
          white_player.active_squares[:rook].push(square)
          if square.position[0] == 'H'
            square = square.top_adjacent
            next
          end
        elsif %w[B G].include?(square.position[0])
          square.current_piece = Piece.new(:White, :knight)
          white_player.active_squares[:knight].push(square)
        elsif %w[C F].include?(square.position[0])
          square.current_piece = Piece.new(:White, :bishop)
          white_player.active_squares[:bishop].push(square)
        elsif square.position[0] == 'D'
          square.current_piece = Piece.new(:White, :queen)
          white_player.active_squares[:queen] = [square]
        elsif square.position[0] == 'E'
          square.current_piece = Piece.new(:White, :king)
          white_player.active_squares[:king] = [square, false]
        end
        square = square.right_adjacent
      when 2
        square.current_piece = Piece.new(:White, :pawn)
        white_player.active_squares[:pawn].push(square)
        if square.position[0] == 'A'
          square = square.top_adjacent
          white_player.active_squares[:pawn].push(square)
          next
        end
        square = square.left_adjacent
      # 7 and 8 cases (ranks) place black pieces
      when 7
        square.current_piece = Piece.new(:Black, :pawn)
        black_player.active_squares[:pawn].push(square)
        if square.position[0] == 'H'
          square = square.top_adjacent
          next
        end
        square = square.right_adjacent
      when 8
        if %w[A H].include?(square.position[0])
          square.current_piece = Piece.new(:Black, :rook)
          black_player.active_squares[:rook].push(square)
        elsif %w[B G].include?(square.position[0])
          square.current_piece = Piece.new(:Black, :knight)
          black_player.active_squares[:knight].push(square)
        elsif %w[C F].include?(square.position[0])
          square.current_piece = Piece.new(:Black, :bishop)
          black_player.active_squares[:bishop].push(square)
        elsif square.position[0] == 'D'
          square.current_piece = Piece.new(:Black, :queen)
          black_player.active_squares[:queen] = [square]
        elsif square.position[0] == 'E'
          square.current_piece = Piece.new(:Black, :king)
          black_player.active_squares[:king] = [square, false]
        end
        break if square.position == ['A', 8]

        square = square.left_adjacent
      else
        square = square.top_adjacent
      end
    end
  end
end
