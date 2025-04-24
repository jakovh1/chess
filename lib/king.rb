# frozen_string_literal: true

require_relative './piece'
require_relative './constants/directions'
require_relative './modules/check_detector'

class King < Piece
  include Directions
  include CheckDetector

  attr_accessor :moved

  def initialize(color)
    super(color, :king)
    @moved = false
  end
  # Generates all possible legal moves for a king.
  # - Iterates through all possible movement directions.
  # - Checks if moving the king to each square would result in a check.
  # - Skips square where the king would be in check.
  # - Adds safe squares to the result array.
  def generate_available_positions(start_square, opponent_color, current_king)
    positions = []
    aux_variable = start_square.current_piece
    start_square.current_piece = nil
    (ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS).each do |direction|
      square = start_square.public_send("#{direction}_adjacent")
      if square && (square.current_piece.nil? || (square.current_piece.color == opponent_color && square.current_piece.name != :king))
        next if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS, :rook)[0]

        next if king_checked?(square, opponent_color, DIAGONAL_DIRECTIONS, :bishop)[0]

        next if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, :queen)[0]

        next if attacked_by_knight?(square, opponent_color)[0]

        next if attacked_by_pawn?(square, opponent_color)[0]

        next if attacked_by_king?(square, opponent_color)

        positions.push(square.position)
      end
    end
    start_square.current_piece = aux_variable
    positions + castling_check(start_square, opponent_color)
  end

  private

  def castling_check(start_square, opponent_color)
    result = []
    return result if @moved == true

    directions = %w[left_adjacent right_adjacent]
    left_rook = start_square.left_adjacent.left_adjacent.left_adjacent.left_adjacent
    right_rook = start_square.right_adjacent.right_adjacent.right_adjacent

    directions.each do |direction|
      square = start_square
      c = direction == directions[0] ? 3 : 2
      next if c == 3 && (left_rook.current_piece&.name != :rook || left_rook.current_piece.moved)

      next if c == 2 && (right_rook.current_piece&.name != :rook || right_rook.current_piece.moved)

      loop_counter = 0

      c.times do
        square = square.public_send("#{direction}")
        break unless square.current_piece.nil?

        break if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS, :rook)[0]

        break if king_checked?(square, opponent_color, DIAGONAL_DIRECTIONS, :bishop)[0]

        break if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, :queen)[0]

        break if attacked_by_knight?(square, opponent_color)[0]

        break if attacked_by_pawn?(square, opponent_color)[0]

        break if attacked_by_king?(square, opponent_color)

        loop_counter += 1
      end
      next if loop_counter != c

      if c == 3
        result.push(square.right_adjacent.position)
      else
        result.push(square.position)
      end
    end
    result
  end
end