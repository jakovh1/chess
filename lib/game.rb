# frozen_string_literal: true

require 'curses'

require_relative './board'
require_relative './board_renderer'
require_relative './player'
require_relative './constants/figures'
require_relative './constants/movement_rules'
require_relative './constants/directions'
require_relative './constants/interposition_generator'

class Game
  include Curses
  include CheckDetection
  include InterpositionGenerator
  include Directions


  def initialize
    @winner = nil
    @selected_piece = nil
    @old_square = nil
    @new_square = nil
    @available_positions = []
    @white_player = Player.new(:White)
    @black_player = Player.new(:Black)
    @current_player = @white_player
    @inactive_player = @black_player
    @message = nil
  end

  def play
    Curses.init_screen
    Curses.stdscr.keypad(true) # Enable arrow key detection
    Curses.noecho
    begin
      board = Board.new(@white_player, @black_player)
      board_renderer = BoardRenderer.new
      board_renderer.render(board, @current_player)
      is_king_checked = [false, []]

      loop do
        # Stores the current king's square in the variable to access it later for check checkup
        current_king = @current_player.active_squares[:king].first
        #active_player = instance_variable_get("@#{@current_player.to_s.downcase}_player")
        # active_player.active_squares.each do |key, value|
        #   value.each do |square|
        #     File.open("log.txt", "a") do |file|
        #       #file.puts "Name: #{key}, Type: #{value.class}, Length: #{value.length}"
        #       file.puts(square) if key == :queen
        #       file.puts(square.current_piece) if key == :queen
        #       file.puts(square.position) if key == :queen
        #     end
        #   end
        # end
        # Checks whether current king is checked.
        is_king_checked = check_checkup(current_king)
        if is_king_checked[0]
          @message = 'The king is checked.'
          if checkmate_lookup(is_king_checked, current_king)
            @winner = true
            @message = "Checkmate. #{@inactive_player.color.to_s} player has won the game."
            board_renderer.render(board, @current_player.color.to_s, @available_positions, @message)
            break
          end
        end
        # Renders the board to the terminal.
        board_renderer.render(board, @current_player.color.to_s, @available_positions, @message)

        case Curses.getch
        when Curses::KEY_UP
          if board.cursor_y >= 3
            board.cursor_y -= 1
            board.current_square = board.current_square.top_adjacent
          end
        when Curses::KEY_DOWN
          if board.cursor_y <= 8
            board.cursor_y += 1
            board.current_square = board.current_square.bottom_adjacent
          end
        when Curses::KEY_LEFT
          if board.cursor_x >= 5
            board.cursor_x -= 3
            board.current_square = board.current_square.left_adjacent
          end
        when Curses::KEY_RIGHT
          if board.cursor_x <= 20
            board.cursor_x += 3
            board.current_square = board.current_square.right_adjacent
          end
        when 10
          current_piece = board.current_square.current_piece
          # The following block will be executed if king is not checked, and current player's piece is selected.
          # It generates available positions for selected piece.
          if @selected_piece.nil? && current_piece&.color == @current_player.color

            @available_positions = current_piece.generate_available_positions(board.current_square, @inactive_player.color)
            filter_available_positions(board, current_king) if current_piece.name != :king
            unless @available_positions.empty?

              @selected_piece = current_piece
              @old_square = board.current_square
              @message = 'Press "u" if you want to unselect currently selected piece.'
            end

          # The following block moves selected piece and captures the opponent's piece if it occupies selected square.
          elsif @available_positions.include?(board.current_square.position) # && !@selected_piece.nil?

            # Checks whether selected square is occupied by opponent's piece and deletes (captures) it if it is.
            if @inactive_player.color == current_piece&.color && current_piece.name != :king

              delete_active_square(current_piece, board)
              capture_handler(board) if current_piece.name != :pawn
            end

            # Puts player's selected piece onto the selected square.
            board.current_square.current_piece = @selected_piece
            current_piece = board.current_square.current_piece
            @old_square.current_piece = nil

            case current_piece
            when Pawn
              promotion(board, board_renderer)
              handle_en_passant(board)
              handle_double_step(board, current_piece)
            when King
              castling(board) if %w[C G].include?(board.current_square.position[0]) && !current_piece.moved
              current_piece.moved = true
            when Rook
              current_piece.moved = true
            end

            update_piece_squares(board.current_square)

            reset_en_passant_flag

            # Reseting everything to nil for the next move.
            reset_to_nil
            @current_player, @inactive_player = @inactive_player, @current_player
          end

        # The following block unselects selected piece.
        when 'u', 'U'
          reset_to_nil
        # Terminates the game.
        when 'q', 'Q'
          break
        end
      end
    ensure
      sleep 7 if @winner
      Curses.clear
      Curses.refresh
      Curses.close_screen
    end
    Curses.close_screen
  end

  private

  def reset_to_nil
    @selected_piece = nil
    @available_positions = []
    @message = nil
  end

  def reset_en_passant_flag
    return unless @inactive_player.recently_moved_pawn

    @inactive_player.recently_moved_pawn.en_passant_target = false
    @inactive_player.recently_moved_pawn = nil
  end

  def delete_active_square(current_piece, board)
    opponent_active_squares = @inactive_player.active_squares[current_piece.name]

    opponent_active_squares.each_with_index do |square, i|
      if square.position == board.current_square.position
        opponent_active_squares.delete(opponent_active_squares[i])
        break
      end
    end
  end

  def handle_double_step(board, current_piece)
    return unless (board.current_square.position[1] - @old_square.position[1]).abs == 2

    current_piece.en_passant_target = true
    @current_player.recently_moved_pawn = current_piece
  end

  def handle_en_passant(board)
    potential_opponent_pawn = @current_player.color == :White ? board.current_square.bottom_adjacent : board.current_square.top_adjacent
    return unless potential_opponent_pawn.current_piece.is_a?(Pawn) && potential_opponent_pawn.current_piece.en_passant_target

    opponent_pawn_squares = @inactive_player.active_squares[:pawn]
    opponent_pawn_squares.each_with_index do |square, i|
      if square.position == potential_opponent_pawn.position
        opponent_pawn_squares.delete(opponent_pawn_squares[i])
        break
      end
    end
    potential_opponent_pawn.current_piece = nil
  end

  def checkmate_lookup(is_checked, current_king)
    checkmate = true
    king_available_positions = current_king.current_piece.generate_available_positions(current_king, @inactive_player.color)
    return nil unless king_available_positions.empty?

    attacker = is_checked[1].select { |subarray| subarray.first == true }
    return checkmate if attacker.length > 1

    interpositions = generate_interposition_squares(attacker[0][1], current_king)
    @current_player.active_squares.each do |key, value|
      value.each do |square|
        next if square.current_piece.name == :king

        available_positions = square.current_piece.generate_available_positions(square, @inactive_player.color)
        available_positions = interpositions & available_positions
        checkmate = false unless available_positions.empty?
        break unless checkmate
      end
      break unless checkmate
    end
    checkmate
  end

  def promotion(board, board_renderer)
    return unless [1, 8].include?(board.current_square.position[1])

    aux_cursor_x = board.cursor_x
    aux_cursor_y = board.cursor_y
    board.cursor_x = 2
    board.cursor_y = @current_player.color == :White ? 1 : 11
    current_color = @current_player.color.to_s.downcase
    #active_player = @current_player.to_s.downcase
    board.public_send("current_#{current_color}_captured_piece=", board.public_send("#{current_color}_captured_pieces"))
    current_captured_piece = board.public_send("current_#{current_color}_captured_piece")
    @message = 'Choose a piece for promotion.'
    @available_positions = []
    board_renderer.render(board, @current_player, @available_positions, @message)
    loop do
      key = Curses.getch
      if key == 10
        board.current_square.current_piece = current_captured_piece
        @current_player.active_squares[board.current_square.current_piece.name].push(board.current_square)
        @current_player.active_squares[:pawn].each_with_index do |square, i|
          if board.current_square.position == square.position
            @current_player.active_squares[:pawn].delete(i)
            break
          end
        end
        board.cursor_x = aux_cursor_x
        board.cursor_y = aux_cursor_y
        break
      end
      current_captured_piece, shift = promotion_keypress_handler(key, current_captured_piece)
      board.cursor_x += shift unless shift.zero?
      board.public_send("current_#{current_color}_captured_piece=", current_captured_piece)
      board_renderer.render(board, @current_player.color.to_s, @available_positions, @message)
    end
  end

  def promotion_keypress_handler(key, current_piece)
    case key
    when Curses::KEY_RIGHT
      return current_piece.right_adjacent, 3 if current_piece.right_adjacent
    when Curses::KEY_LEFT
      return current_piece.left_adjacent, -3 if current_piece.left_adjacent
    end
    [current_piece, 0]
  end

  # Checks whether king is checked and returns the square which checks the king.
  def check_checkup(current_king)
    king_checked_rook = king_checked?(current_king, @inactive_player.color, ORTHOGONAL_DIRECTIONS, 'rook')
    king_checked_bishop = king_checked?(current_king, @inactive_player.color, DIAGONAL_DIRECTIONS, 'bishop')
    king_checked_queen = king_checked?(current_king, @inactive_player.color, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, 'queen')
    king_checked_knight = attacked_by_knight?(current_king, @inactive_player.color)
    king_checked_pawn = attacked_by_pawn?(current_king, @inactive_player.color)

    is_king_checked = king_checked_queen[0] || king_checked_rook[0] || king_checked_bishop[0] || king_checked_knight[0] || king_checked_pawn[0]
    [is_king_checked, [king_checked_rook, king_checked_bishop, king_checked_knight, king_checked_pawn, king_checked_queen]]
  end

  def capture_handler(board)
    last_captured_piece = board.public_send("#{@inactive_player.color.to_s.downcase}_captured_pieces")
    already_captured = false
    tail = nil
    if last_captured_piece
      while last_captured_piece
        if last_captured_piece.symbol == board.current_square.current_piece.symbol
          already_captured = true
          break
        else
          tail = last_captured_piece
          last_captured_piece = last_captured_piece.right_adjacent
        end
      end
      unless already_captured
        tail.right_adjacent = board.current_square.current_piece.dup
        tail.right_adjacent.left_adjacent = tail
      end
    else
      board.public_send("#{@inactive_player.color.to_s.downcase}_captured_pieces=", board.current_square.current_piece.dup)
      #File.open("log.txt", "a") { |file| file.puts(board.public_send("#{@inactive_player.to_s.downcase}_captured_pieces").current_piece.symbol) }
    end
    board.current_square.current_piece = nil
  end

  # Updates the player's piece and its new square.
  def update_piece_squares(square)
    case @selected_piece.symbol
    when '♛', '♕'
      @current_player.active_squares[:queen] = [square]
    when '♔', '♚'
      @current_player.active_squares[:king] = [square]
    else
      active_squares_piece = @current_player.active_squares[@selected_piece.name]
      active_squares_piece.each_with_index do |figure, i|
        if figure.position == @old_square.position
          active_squares_piece[i] = square
          break
        end
      end
    end
  end

  # Handles the castling
  def castling(board)
    new_square = nil
    aux_old_square = @old_square
    aux_selected_piece = @selected_piece
    if board.current_square.position[0] == 'G'
      board.current_square.left_adjacent.current_piece = board.current_square.right_adjacent.current_piece
      board.current_square.right_adjacent.current_piece = nil
      new_square = board.current_square.left_adjacent
      @old_square = board.current_square.right_adjacent
    elsif board.current_square.position[0] == 'C'
      board.current_square.right_adjacent.current_piece = board.current_square.left_adjacent.left_adjacent.current_piece
      board.current_square.left_adjacent.left_adjacent.current_piece = nil
      new_square = board.current_square.right_adjacent
      @old_square = board.current_square.left_adjacent.left_adjacent
    end
    @selected_piece = new_square.current_piece
    @selected_piece.moved = true
    update_piece_squares(new_square)
    @old_square = aux_old_square
    @selected_piece = aux_selected_piece
  end

  def filter_available_positions(board, king)
    aux_variable = board.current_square.current_piece
    board.current_square.current_piece = nil
    is_king_checked = check_checkup(king)

    if is_king_checked[0]
      attacker = is_king_checked[1].select { |subarray| subarray.first == true }
      interpositions = generate_interposition_squares(attacker[0][1], king)
      @available_positions = interpositions & @available_positions
    end

    board.current_square.current_piece = aux_variable
    @available_positions
  end
end