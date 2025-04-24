# frozen_string_literal: true

require_relative './square'
require_relative './pieces/pawn'
require_relative './pieces/bishop'
require_relative './pieces/queen'
require_relative './pieces/king'
require_relative './pieces/knight'
require_relative './pieces/rook'

class Board
  attr_accessor :board, :cursor_x, :cursor_y, :current_square, :white_captured_pieces, :black_captured_pieces, :current_white_captured_piece, :current_black_captured_piece

  def initialize(white_player, black_player)
    @board = Square.new('black', ['A', 1], nil, nil, nil, nil, nil, nil, nil, nil, nil)
    @cursor_x = 2
    @cursor_y = 9
    @current_square = @board
    @white_captured_pieces = nil
    @current_white_captured_piece = @white_captured_pieces
    @black_captured_pieces = nil
    @current_black_captured_piece = @black_captured_pieces
    generate_board(white_player, black_player)
  end

  private

  def generate_board(white_player, black_player)
    square = @board
    square = generate_square_row(square) until square.position == ['A', 8]
    if square.position[1] == 8
      square = square.right_adjacent until square.right_adjacent.nil?
    end
    square = establish_relationships(square) until square.position == ['A', 1]
    place_pieces(white_player, black_player)
  end

  # toggles the square background color
  def toggle_color(square)
    return 'white' if square.color == 'black'

    'black'
  end

  def generate_square_row(square)
    direction, destination_file, file_shift, new_link = square.position[0] == 'A' ? [:right_adjacent, 'H', 1, 'left_adjacent'] : [:left_adjacent, 'A', -1, 'right_adjacent']

    until square.position[0] == destination_file
      square.send("#{direction}=", Square.new(toggle_color(square), [(square.position[0].ord + file_shift).chr, square.position[1]]))
      square.send(direction).send("#{new_link}=", square)
      square = square.send(direction)
    end
    return square if square.position == ['A', 8]

    square.top_adjacent = Square.new(toggle_color(square), [square.position[0], square.position[1] + 1])
    square.top_adjacent.bottom_adjacent = square
    square.top_adjacent
  end

  def establish_relationships(square)
    second_square = square.bottom_adjacent

    adjacents, destination_file = second_square.position[0] == 'A' ? 
    [['top_right_adjacent', 'right_adjacent', 'bottom_left_adjacent', 'left_top_adjacent', 'right_bottom_adjacent'], 'H'] : 
    [['left_top_adjacent', 'left_adjacent', 'right_bottom_adjacent', 'top_right_adjacent', 'bottom_left_adjacent'], 'A']

    until second_square.position[0] == destination_file
      second_square.send("#{adjacents[0]}=", square.send(adjacents[1]))
      square.send(adjacents[1]).send("#{adjacents[2]}=", second_square)

      second_square.send(adjacents[1]).send("#{adjacents[3]}=", square)
      square.send("#{adjacents[4]}=", second_square.send(adjacents[1]))

      second_square.send(adjacents[1]).top_adjacent = square.send(adjacents[1])
      square.send(adjacents[1]).bottom_adjacent = second_square.send(adjacents[1])

      square = square.send(adjacents[1])
      second_square = second_square.send(adjacents[1])
    end
    second_square
  end

  def place_pieces(white_player, black_player)
    place_major_pieces(@current_square, 1, :White, white_player)
    place_pawns(@current_square, 2, :White, white_player)
    place_pawns(@current_square, 7, :Black, black_player)
    place_major_pieces(@current_square, 8, :Black, black_player)
  end

  def place_major_pieces(square, rank, color, player)
    square = square.top_adjacent while square.position[1] < rank
    piece_order = %i[rook knight bishop queen king bishop knight rook]
    piece_classes = {
      rook: Rook,
      knight: Knight,
      bishop: Bishop,
      queen: Queen,
      king: King
    }
    piece_order.each do |piece|
      square.current_piece = piece_classes[piece].new(color)
      if %i[rook knight bishop].include?(piece)
        player.active_squares[piece].push(square)
      else
        player.active_squares[piece] = [square]
      end
      square = square.right_adjacent
    end
  end

  def place_pawns(square, rank, color, player)
    square = square.top_adjacent while square.position[1] < rank
    while square
      square.current_piece = Pawn.new(color)
      player.active_squares[:pawn].push(square)
      square = square.right_adjacent
    end
  end
end
