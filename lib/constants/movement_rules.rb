# frozen_string_literal: true

require_relative './figures'
require_relative './directions'

module LinearMovement

  # Generates all possible legal moves for rooks, bishops and queens.
  # - Iterates through all linear (sliding) movement directions.
  # - For each direction, calls '#linear_traversal' method which returns a 2d array with legal positions.
  # - '#flat_map' enumerable flattens the many 2d arrays into 1 2d array.
  def generate_linear_moves(start_square, opponent_color, directions)
    directions.flat_map do |direction|
      linear_traversal(start_square, direction, opponent_color)
    end
  end

  # Generates all possible squares (positions) for the given direction.
  # - Traverses in a given direction and adds position of the square to the result array
  # - if the square is empty or occupied by the opponent's piece.
  def linear_traversal(start_square, direction, opponent_color)
    positions = []
    loop do
      break if start_square.public_send("#{direction}_adjacent").nil?

      if start_square.public_send("#{direction}_adjacent")&.current_piece.nil?
        positions.push(start_square.public_send("#{direction}_adjacent").position)
        start_square = start_square.public_send("#{direction}_adjacent")
      elsif Object.const_get("#{opponent_color.upcase}_FIGURES").include?(start_square.public_send("#{direction}_adjacent").current_piece.symbol)
        positions.push(start_square.public_send("#{direction}_adjacent").position)
        break
      else
        break
      end
    end
    positions
  end
end

module CheckDetection
  include Directions
  # Checks if the opponent's king attacks the given square where the king might move.
  # - Iterates through all possible movement directions of the king.
  # - Checks whether opponent's king occupies the given square.
  # - Returns true if the opponent's king attacks the potential square.
  def attacked_by_king?(square, opponent_color)
    attacked = false
    start_square = square
    (ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS).each do |direction|
      square = square.public_send("#{direction}_adjacent")
      if square&.current_piece&.symbol == PIECE_UNICODE[opponent_color.to_sym][:king]
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
    directions = opponent_color == :White ? %w[right_bottom_adjacent bottom_left_adjacent] : %w[left_top_adjacent top_right_adjacent]
    start_square = square
    directions.each do |direction|
      square = square.public_send("#{direction}")
      if square&.current_piece&.symbol == PIECE_UNICODE[opponent_color.to_sym][:pawn]
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
  def king_checked?(square, opponent_color, directions, opponent_figure)
    result = [false]
    start_square = square
    catch :exit_outer_loop do
      directions.each do |direction|
        loop do
          break if square.public_send("#{direction}_adjacent").nil?

          if square.public_send("#{direction}_adjacent")&.current_piece.nil?
            square = square.public_send("#{direction}_adjacent")

          elsif PIECE_UNICODE[opponent_color.to_sym][opponent_figure.to_sym] == square.public_send("#{direction}_adjacent").current_piece.symbol
            result[0] = true
            result.push(square.public_send("#{direction}_adjacent"))
            throw :exit_outer_loop if opponent_figure == 'queen'
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
        next unless adjacent_square&.current_piece&.symbol == PIECE_UNICODE[opponent_color.to_sym][:knight]

        result[0] = true
        result.push(adjacent_square)
      end

      square = start_square
    end
    result
  end
end
