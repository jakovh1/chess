# frozen_string_literal: true

require_relative '../constants/symbols'
require_relative '../constants/directions'

require_relative './interposition_generator'

module CheckDetector
  include Directions
  include Symbols

  include InterpositionGenerator

  def filter_available_positions(positions, square, current_king, opponent_color)
    aux_variable = square.current_piece
    square.current_piece = nil
    is_king_checked = check_checkup(current_king, opponent_color)

    if is_king_checked[0]
      attacker = is_king_checked[1].select { |piece| piece.first == true }
      interpositions = generate_interposition_squares(attacker[0][1], current_king)
      positions = interpositions & positions
    end
    square.current_piece = aux_variable
    positions
  end

  # Checks whether king is checked and returns the square which checks the king.
  def check_checkup(current_king, opponent_color)
    king_checked_rook = king_checked?(current_king, opponent_color, ORTHOGONAL_DIRECTIONS, :rook)
    king_checked_bishop = king_checked?(current_king, opponent_color, DIAGONAL_DIRECTIONS, :bishop)
    king_checked_queen = king_checked?(current_king, opponent_color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, :queen)
    king_checked_knight = attacked_by_knight?(current_king, opponent_color)
    king_checked_pawn = attacked_by_pawn?(current_king, opponent_color)

    is_king_checked = king_checked_queen[0] || king_checked_rook[0] || king_checked_bishop[0] || king_checked_knight[0] || king_checked_pawn[0]
    [is_king_checked, [king_checked_rook, king_checked_bishop, king_checked_knight, king_checked_pawn, king_checked_queen]]
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
      if square&.current_piece&.symbol == SYMBOLS[opponent_color][:king]
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
      if square&.current_piece&.symbol == SYMBOLS[opponent_color][:pawn]
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

          elsif SYMBOLS[opponent_color][opponent_figure.to_sym] == square.public_send("#{direction}_adjacent").current_piece.symbol
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
        next unless adjacent_square&.current_piece&.symbol == SYMBOLS[opponent_color.to_sym][:knight]

        result[0] = true
        result.push(adjacent_square)
      end

      square = start_square
    end
    result
  end
end
