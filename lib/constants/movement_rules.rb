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

def generate_pawn_moves(start_square)
  positions = []
  if WHITE_FIGURES.include?(start_square.current_piece)
    positions.push(start_square.top_adjacent.position) if start_square.top_adjacent.current_piece.nil?
    positions.push(start_square.top_right_adjacent.position) if BLACK_FIGURES.include?(start_square.top_right_adjacent&.current_piece)
    positions.push(start_square.left_top_adjacent.position) if BLACK_FIGURES.include?(start_square.left_top_adjacent&.current_piece)
    if start_square.position[1] == 2 && start_square.top_adjacent.current_piece.nil?
      positions.push(start_square.top_adjacent.top_adjacent.position)
    end
  else
    positions.push(start_square.bottom_adjacent.position) if start_square.bottom_adjacent.current_piece.nil?
    positions.push(start_square.right_bottom_adjacent.position) if WHITE_FIGURES.include?(start_square.right_bottom_adjacent&.current_piece)
    positions.push(start_square.bottom_left_adjacent.position) if WHITE_FIGURES.include?(start_square.bottom_left_adjacent&.current_piece)
    if start_square.position[1] == 7 && start_square.bottom_adjacent.current_piece.nil?
      positions.push(start_square.bottom_adjacent.bottom_adjacent.position)
    end
  end
  positions
end

def generate_king_moves(start_square, opponent_color, directions)
  positions = []
  directions.each do |direction|
    square = start_square.public_send("#{direction}_adjacent")
    if square && (square.current_piece.nil? || Object.const_get("#{opponent_color.upcase}_FIGURES").include?(square.current_piece))
      next if king_checked?(square, opponent_color, DIRECTIONS, 'rook')[0]

      next if king_checked?(square, opponent_color, BISHOP_DIRECTIONS, 'bishop')[0]

      next if king_checked?(square, opponent_color, DIRECTIONS + BISHOP_DIRECTIONS, 'queen')[0]

      next if legal_by_knight?(square, opponent_color)[0]

      next if legal_by_pawn?(square, opponent_color)[0]

      next unless legal_by_king?(square, opponent_color)

      positions.push(square.position)
    end
  end
  positions
end

def generate_linear_moves(start_square, opponent_color, directions)
  directions.flat_map do |direction|
    linear_traversal(start_square, direction, opponent_color)
  end
end

def legal_by_king?(square, opponent_color)
  legal = true
  directions = DIRECTIONS + BISHOP_DIRECTIONS
  start_square = square
  directions.each do |direction|
    square = square.public_send("#{direction}_adjacent")
    if square&.current_piece == PIECE_UNICODE[opponent_color.to_sym][:king]
      legal = false
      break
    else
      square = start_square
      next
    end
  end
  legal
end

def legal_by_pawn?(square, opponent_color)
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

def legal_by_knight?(square, opponent_color)
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

def generate_knight_moves(start_square, opponent_color, directions)
  directions.flat_map do |direction|
    knight_traversal(start_square, direction, opponent_color)
  end
end

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

def generate_interposition_squares(attacking_square, king_square)
  case attacking_square.current_piece
  when '♖', '♜'
    interposition_squares = attacking_rook(attacking_square, king_square)
  when '♗', '♝'
    interposition_squares = attacking_bishop(attacking_square, king_square)
  when '♛', '♕'
    interposition_squares = attacking_square.position[0] == king_square.position[0] || attacking_square.position[1] == king_square.position[1] ? attacking_rook(attacking_square, king_square) : attacking_bishop(attacking_square, king_square)
  when '♞', '♘'
    interposition_squares = attacking_square.position
  when '♙', '♟'
    interposition_squares = attacking_square.position
  end
end

def attacking_rook(attacking_square, king_square)
  result = []
  if attacking_square.position[0] == king_square.position[0]
    min, max = [attacking_square.position[1], king_square.position[1]].sort
    between_ranks = (min..max).to_a
    between_ranks.each do |n|
      result.push([attacking_square.position[0], n])
    end
  else
    min, max = [attacking_square.position[0], king_square.position[0]].sort
    between_files = (min..max).to_a
    between_files.each do |f|
      result.push([f, king_square.position[0]])
    end
  end
  result.delete(king_square.position)
  result
end

def attacking_bishop(attacking_square, king_square)
  result = []
  min_file, max_file = [attacking_square.position[0], king_square.position[0]].sort
  between_files = (min_file..max_file).to_a
  
  min_rank, max_rank = [attacking_square.position[1], king_square.position[1]].sort
  between_ranks = (min_rank..max_rank).to_a
  unless [attacking_square.position, king_square.position].include?([between_files[0], between_ranks[0]])
    between_ranks.reverse!
  end

  between_ranks.each_with_index do |r, i|
    result.push([between_files[i], r])
  end

  result.delete(king_square.position)
  result
end