# frozen_string_literal: true

require_relative './piece'

class Pawn < Piece
  attr_accessor :en_passant_target

  def initialize(color)
    super(color, :pawn)
    @en_passant_target = false
  end

  # Generates all possible moves for a pawn.
  # - Adds forward movement if the square is empty. *(1)
  # - Adds a double step if the pawn is on its initial rank and both squares are empty. *(2)
  # - Adds diagonal squares if an opponent's piece is present. *(3)
  def generate_available_positions(start_square, opponent_color)
    positions = []
    initial_rank = opponent_color == :White ? 7 : 2
    directions = opponent_color == :Black ? %w[top_adjacent top_right_adjacent left_top_adjacent] : %w[bottom_adjacent right_bottom_adjacent bottom_left_adjacent]

    forward_move = start_square.public_send("#{directions[0]}")
    right_capture = start_square.public_send("#{directions[1]}")
    left_capture = start_square.public_send("#{directions[2]}")

    

    # *(1)
    if forward_move.current_piece.nil?
      positions.push(forward_move.position)
      double_step = forward_move.public_send("#{directions[0]}")
      positions.push(double_step.position) if start_square.position[1] == initial_rank && double_step.current_piece.nil? # *(2)
    end



    # en_passant check
    if start_square.current_piece.color == :White && start_square.position[1] == 5
      positions.push(start_square.left_top_adjacent.position) if start_square.left_adjacent&.current_piece&.name == :pawn && start_square.left_adjacent.current_piece.en_passant_target
      positions.push(start_square.top_right_adjacent.position) if start_square.right_adjacent&.current_piece&.name == :pawn && start_square.right_adjacent.current_piece.en_passant_target
    elsif start_square.current_piece.color == :Black && start_square.position[1] == 4
      positions.push(start_square.bottom_left_adjacent.position) if start_square.left_adjacent&.current_piece&.name == :pawn && start_square.left_adjacent.current_piece.en_passant_target
      positions.push(start_square.right_bottom_adjacent.position) if start_square.right_adjacent&.current_piece&.name == :pawn && start_square.right_adjacent.current_piece.en_passant_target
    end

    # *(3)
    positions.push(right_capture.position) if right_capture&.current_piece&.color == opponent_color && right_capture.current_piece.name != :king
    positions.push(left_capture.position) if left_capture&.current_piece&.color == opponent_color && left_capture.current_piece.name != :king
    positions
  end
end