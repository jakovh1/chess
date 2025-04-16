# frozen_string_literal: true

require_relative './piece'
require_relative './constants/directions'
require_relative './constants/movement_rules'

class King < Piece
  include Directions
  include CheckDetection

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
  def generate_available_positions(start_square, opponent_color)
    positions = []
    aux_variable = start_square.current_piece
    start_square.current_piece = nil
    (ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS).each do |direction|
      square = start_square.public_send("#{direction}_adjacent")
      if square && (square.current_piece.nil? || (square.current_piece.color == opponent_color && square.current_piece.name != :king))
        next if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS, 'rook')[0]

        next if king_checked?(square, opponent_color, DIAGONAL_DIRECTIONS, 'bishop')[0]

        next if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, 'queen')[0]

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

        break if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS, 'rook')[0]

        break if king_checked?(square, opponent_color, DIAGONAL_DIRECTIONS, 'bishop')[0]

        break if king_checked?(square, opponent_color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, 'queen')[0]

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

  
 
  # Checks if the opponent's king attacks the given square where the king might move.
  # - Iterates through all possible movement directions of the king.
  # - Checks whether opponent's king occupies the given square.
  # - Returns true if the opponent's king attacks the potential square.
  def attacked_by_king?(square, opponent_color)
    attacked = false
    start_square = square
    (ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS).each do |direction|
      square = square.public_send("#{direction}_adjacent")
      if square&.current_piece&.symbol == PIECE_UNICODE[opponent_color][:king]
        attacked = true
        break
      else
        square = start_square
        next
      end
    end
    attacked
  end

  # Checks if the opponent's pawn attacks the given square where the king might move.
  # - Iterates through 2 possible capture movement directions of the pawn.
  # - Checks whether opponent's pawn occupies the given square.
  # - Returns true if the opponent's pawn attacks the potential square.
  def attacked_by_pawn?(square, opponent_color)
    result = [false]
    directions = opponent_color == 'White' ? %w[right_bottom_adjacent bottom_left_adjacent] : %w[left_top_adjacent top_right_adjacent]
    start_square = square
    directions.each do |direction|
      square = square.public_send("#{direction}")
      if square&.current_piece&.symbol == PIECE_UNICODE[opponent_color][:pawn]
        result[0] = true
        result.push(square)
      else
        square = start_square
        next
      end
    end
    result
  end

  # Checks whether king is checked by rook, bishop or queen.
  # - Iterates through all possible movement directions, depending on the 'directions' parameter.
  # - Starting from the king's square, traverses through each direction until opponent's piece (rook, bishop or queen), it's own piece, or the end of the chess table is found.
  # - returns 'true' and opponent's square if it's occupied by a piece which checks the king, and 'false' otherwise.
  def king_checked?(square, opponent_color, directions, opponent_piece)
    result = [false]
    start_square = square
    catch :exit_outer_loop do
      directions.each do |direction|
        loop do
          break if square.public_send("#{direction}_adjacent").nil?

          if square.public_send("#{direction}_adjacent")&.current_piece.nil?
            square = square.public_send("#{direction}_adjacent")

          elsif PIECE_UNICODE[opponent_color][opponent_piece.to_sym] == square.public_send("#{direction}_adjacent").current_piece.symbol
            result[0] = true
            result.push(square.public_send("#{direction}_adjacent"))
            throw :exit_outer_loop if opponent_piece == 'queen'
            break
          else
            break
          end
        end
        square = start_square
      end
    end
    result
  end

  # Checks whether king, or the square where king might move to, is attacked by a knight.
  # - Moves 2 squares in the given direction and 1 square perpendicular.
  # - Checks if a destination square is occupied by the opponent's knight.
  # - If yes, returns 'true' and square which is occupied by the opponent's knight
  def attacked_by_knight?(square, opponent_color)
    result = [false]
    start_square = square
    ORTHOGONAL_DIRECTIONS.each do |direction|
      skip = false
      2.times do
        if square.public_send("#{direction}_adjacent").nil?
          skip = true
          break
        end

        square = square.public_send("#{direction}_adjacent")
      end

      if skip
        square = start_square
        next
      end

      branches = %w[top bottom].include?(direction) ? %w[right left] : %w[top bottom]

      branches.each do |branch|
        adjacent_square = square.public_send("#{branch}_adjacent")
        next unless adjacent_square&.current_piece&.symbol == PIECE_UNICODE[opponent_color][:knight]

        result[0] = true
        result.push(adjacent_square)
      end

      square = start_square
    end
    result
  end

end