# frozen_string_literal: true

require_relative './figures'
require_relative './directions'

module MovementRules
  MOVEMENT_RULES = {
    pawn: ->(start_square) { generate_pawn_moves(start_square) },
    rook: ->(start_square, opponent_color, directions) { generate_linear_moves(start_square, opponent_color, directions) },
    knight: ->(start_square, opponent_color, directions) { generate_knight_moves(start_square, opponent_color, directions) },
    bishop: ->(start_square, opponent_color, directions) { generate_linear_moves(start_square, opponent_color, directions) },
    queen: ->(start_square, opponent_color, directions) { generate_linear_moves(start_square, opponent_color, directions) },
    king: ->(start_square, opponent_color, directions) { generate_king_moves(start_square, opponent_color, directions) }
  }.freeze
end

# Generates all possible moves for a pawn.
# - Adds forward movement if the square is empty. *(1)
# - Adds a double step if the pawn is on its initial rank and both squares are empty. *(2)
# - Adds diagonal squares if an opponent's piece is present. *(3)
def generate_pawn_moves(start_square)
  positions = []
  opponent_color = WHITE_FIGURES.include?(start_square.current_piece) ? 'BLACK' : 'WHITE'
  initial_rank = opponent_color == 'WHITE' ? 7 : 2
  directions = opponent_color == 'BLACK' ? %w[top_adjacent top_right_adjacent left_top_adjacent] : %w[bottom_adjacent right_bottom_adjacent bottom_left_adjacent]

  opponent_figures = Object.const_get("#{opponent_color}_FIGURES")
  forward_move = start_square.public_send("#{directions[0]}")
  right_capture = start_square.public_send("#{directions[1]}")
  left_capture = start_square.public_send("#{directions[2]}")

  # *(1)
  if forward_move.current_piece.nil?
    positions.push(forward_move.position)
    double_step = forward_move.public_send("#{directions[0]}")
    positions.push(double_step.position) if start_square.position[1] == initial_rank && double_step.current_piece.nil? # *(2)
  end

  # *(3)
  positions.push(right_capture.position) if opponent_figures.include?(right_capture&.current_piece)
  positions.push(left_capture.position) if opponent_figures.include?(left_capture&.current_piece)
  positions
end

# Generates all possible legal moves for a king.
# - Iterates through all possible movement directions.
# - Checks if moving the king to each square would result in a check.
# - Skips square where the king would be in check.
# - Adds safe squares to the result array.
def generate_king_moves(start_square, opponent_color, directions)
  positions = []
  directions.each do |direction|
    square = start_square.public_send("#{direction}_adjacent")
    if square && (square.current_piece.nil? || Object.const_get("#{opponent_color.upcase}_FIGURES").include?(square.current_piece))
      next if king_checked?(square, opponent_color, DIRECTIONS, 'rook')[0]

      next if king_checked?(square, opponent_color, BISHOP_DIRECTIONS, 'bishop')[0]

      next if king_checked?(square, opponent_color, DIRECTIONS + BISHOP_DIRECTIONS, 'queen')[0]

      next if attacked_by_knight?(square, opponent_color)[0]

      next if attacked_by_pawn?(square, opponent_color)[0]

      next if attacked_by_king?(square, opponent_color)

      positions.push(square.position)
    end
  end
  positions
end

# Generates all possible legal moves for a knight.
# - Iterates through all possible L-shape movement directions.
# - For each direction, calls '#knight_traversal' method which returns a 2d array with legal positions.
# - '#flat_map' enumerable flattens the many 2d arrays into 1 2d array.
def generate_knight_moves(start_square, opponent_color, directions)
  directions.flat_map do |direction|
    knight_traversal(start_square, direction, opponent_color)
  end
end

# Generates possible legal moves for a knight in a given direction.
# - Moves 2 squares in the given direction and 1 square perpendicular.
# - Checks if a destination square is either empty or contains opponent's piece.
# - Adds position of the square to the result if yes.
def knight_traversal(start_square, direction, opponent_color)
  positions = []
  2.times do
    return positions if start_square.public_send("#{direction}_adjacent").nil?

    start_square = start_square.public_send("#{direction}_adjacent")
  end

  branches = %w[top bottom].include?(direction) ? %w[right left] : %w[top bottom]

  branches.each do |branch|
    adjacent_square = start_square.public_send("#{branch}_adjacent")
    if adjacent_square && (adjacent_square.current_piece.nil? ||
                          Object.const_get("#{opponent_color.upcase}_FIGURES").include?(adjacent_square.current_piece))
      positions.push(adjacent_square.position)
    end
  end
  positions
end

# Generates all possible legal moves for rooks, bishops and queens.
# - Iterates through all linear (sliding) movement directions.
# - For each direction, calls '#linear_traversal' method which returns a 2d array with legal positions.
# - '#flat_map' enumerable flattens the many 2d arrays into 1 2d array.
def generate_linear_moves(start_square, opponent_color, directions)
  directions.flat_map do |direction|
    linear_traversal(start_square, direction, opponent_color)
  end
end

# Checks if the opponent's king attacks the given square where the king might move.
# - Iterates through all possible movement directions of the king.
# - Checks whether opponent's king occupies the given square.
# - Returns true if the opponent's king attacks the potential square.
def attacked_by_king?(square, opponent_color)
  attacked = false
  directions = DIRECTIONS + BISHOP_DIRECTIONS
  start_square = square
  directions.each do |direction|
    square = square.public_send("#{direction}_adjacent")
    if square&.current_piece == PIECE_UNICODE[opponent_color.to_sym][:king]
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
    if square&.current_piece == PIECE_UNICODE[opponent_color.to_sym][:pawn]
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

        elsif PIECE_UNICODE[opponent_color.to_sym][opponent_figure.to_sym] == square.public_send("#{direction}_adjacent").current_piece
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
  DIRECTIONS.each do |direction|
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
      next unless adjacent_square&.current_piece == PIECE_UNICODE[opponent_color.to_sym][:knight]

      result[0] = true
      result.push(adjacent_square)
    end

    square = start_square
  end
  result
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
    elsif Object.const_get("#{opponent_color.upcase}_FIGURES").include?(start_square.public_send("#{direction}_adjacent").current_piece)
      positions.push(start_square.public_send("#{direction}_adjacent").position)
      break
    else
      break
    end
  end
  positions
end
