# frozen_string_literal: true

require 'curses'

require_relative './board'
require_relative './board_renderer'
require_relative './player'

require_relative './constants/directions'

require_relative './modules/check_detector'
require_relative './modules/interposition_generator'
require_relative './modules/draw_detector'
require_relative './modules/game_saver'
require_relative './modules/game_loader'

class Game
  include Curses
  include CheckDetector
  include InterpositionGenerator
  include DrawDetector
  include Directions
  include GameSaver
  include GameLoader

  SQUARE_HEIGHT = 1
  SQUARE_WIDTH = 3

  def initialize
    @game_state = nil
    @selected_piece = nil
    @old_square = nil
    @available_positions = []
    @white_player = Player.new(:White)
    @black_player = Player.new(:Black)
    @current_player = @white_player
    @inactive_player = @black_player
    @current_king = nil
    @message = ''
    @any_saved_game = contains_saved_games?
    @message_extension = " Press 's' to save the game. #{@any_saved_game ? "Press 'l' to load a game." : ''}"
  end

  def play
    Curses.init_screen
    Curses.stdscr.keypad(true) # Enable arrow key detection
    Curses.noecho
    begin
      board = Board.new(@white_player, @black_player)
      board_renderer = BoardRenderer.new
      board_renderer.render(board, @current_player)
      @current_king = @current_player.active_squares[:king].first
      loop do
        board_renderer.render(board, @current_player.color.to_s, @available_positions, @message + @message_extension)

        case Curses.getch
        when Curses::KEY_UP
          if board.current_square.top_adjacent
            board.cursor_y -= SQUARE_HEIGHT
            board.current_square = board.current_square.top_adjacent
          end
        when Curses::KEY_DOWN
          if board.current_square.bottom_adjacent
            board.cursor_y += SQUARE_HEIGHT
            board.current_square = board.current_square.bottom_adjacent
          end
        when Curses::KEY_LEFT
          if board.current_square.left_adjacent
            board.cursor_x -= SQUARE_WIDTH
            board.current_square = board.current_square.left_adjacent
          end
        when Curses::KEY_RIGHT
          if board.current_square.right_adjacent
            board.cursor_x += SQUARE_WIDTH
            board.current_square = board.current_square.right_adjacent
          end
        when 10
          handle_enter_key(board, board_renderer)
        when 'u', 'U'
          reset_to_nil
        when 's', 'S'
          @message = 'The game has been saved successfully.' if save_game(board, @selected_piece, @old_square, @available_positions, @white_player, @black_player, @current_player, @inactive_player, @current_king, @message)
          @any_saved_game = contains_saved_games? unless @any_saved_game
        when 'l', 'L'
          game_name = game_selection(get_saved_games, board_renderer)
          game_data = load_game(game_name)
          board = game_data[:board]
          assign_game_state(game_data)
        when 'q', 'Q'
          break
        end
        if @game_state
          board_renderer.render(board, @current_player.color.to_s, @available_positions, @message)
          break
        end
      end
    ensure
      sleep 7 if @game_state
      Curses.clear
      Curses.refresh
      Curses.close_screen
    end
  end

  private

  def assign_game_state(game_data)
    @game_state = game_data[:game_state]
    @selected_piece = game_data[:selected_piece]
    @old_square = game_data[:old_square]
    @available_positions = game_data[:available_positions]
    @white_player = game_data[:white_player]
    @black_player = game_data[:black_player]
    @current_player = game_data[:current_player]
    @inactive_player = game_data[:inactive_player]
    @current_king = game_data[:current_king]
    @message = 'The game has been loaded successfully.'
  end

  def handle_enter_key(board, board_renderer)
    current_piece = board.current_square.current_piece

    if @selected_piece.nil? && piece_valid?(current_piece)

      fetch_available_positions(current_piece, board)
      select_piece(current_piece, board)

    elsif @available_positions.include?(board.current_square.position)
      capture_and_place_piece(board, current_piece)
      current_piece = board.current_square.current_piece
      handle_post_move_actions(board_renderer, board, current_piece)
    end
  end

  def handle_post_move_actions(board_renderer, board, current_piece)
    handle_piece_specific_actions(current_piece, board, board_renderer)
    update_piece_squares(board.current_square)
    reset_en_passant_flag

    # Reseting everything to nil for the next move.
    reset_to_nil
    toggle_players
    check_game_state(board, board_renderer)
  end

  def toggle_players
    @current_player, @inactive_player = @inactive_player, @current_player
    @current_king = @current_player.active_squares[:king].first
  end

  def piece_valid?(current_piece)
    current_piece&.color == @current_player.color
  end

  def fetch_available_positions(current_piece, board)
    @available_positions = current_piece.generate_available_positions(board.current_square, @inactive_player.color, @current_king)
    #filter_available_positions(board) if current_piece.name != :king
  end

  def select_piece(current_piece, board)
    return if @available_positions.empty?

    @selected_piece = current_piece
    @old_square = board.current_square
    @message = 'Press "u" if you want to unselect currently selected piece.'
  end

  def handle_piece_specific_actions(current_piece, board, board_renderer)
    case current_piece
    when Pawn
      pawn_specific_actions(current_piece, board, board_renderer)
    when King
      castling(board.current_square) if %w[C G].include?(board.current_square.position[0]) && !current_piece.moved
      current_piece.moved = true
    when Rook
      current_piece.moved = true
    end
  end

  def pawn_specific_actions(current_piece, board, board_renderer)
    promotion(board, board_renderer)
    handle_en_passant(board)
    handle_double_step(board, current_piece)
  end

  def capture_and_place_piece(board, current_piece)
     # Checks whether selected square is occupied by opponent's piece and deletes (captures) it if it is.
    if @inactive_player.color == current_piece&.color && current_piece.name != :king
      delete_active_square(board.current_square, @inactive_player)
      capture_handler(board) if current_piece.name != :pawn
    end

    # Puts player's selected piece onto the selected square.
    board.current_square.current_piece = @selected_piece
    @old_square.current_piece = nil
  end

  def check_game_state(board, board_renderer)
    # Checks whether current king is checked.
    is_king_checked = check_checkup(@current_king, @inactive_player.color)
    if is_king_checked[0]
      @message = 'The king is checked.'
      return unless checkmate?(is_king_checked[1])

      @game_state = true
      @message = "Checkmate. #{@inactive_player.color} player has won the game."
    elsif stalemate?(@current_player.active_squares, @inactive_player.color, @current_king)
      @game_state = true
      @message = 'Stalemate. Draw.'
    elsif insufficient_material?(@current_player, @inactive_player)
      @game_state = true
      @message = 'Insufficient material. Draw.'
    end
  end

  

  def reset_to_nil
    @selected_piece = nil
    @available_positions = []
    @message = ''
  end

  def reset_en_passant_flag
    return unless @inactive_player.recently_moved_pawn

    @inactive_player.recently_moved_pawn.en_passant_target = false
    @inactive_player.recently_moved_pawn = nil
  end

  def delete_active_square(square_to_delete, player)
    player_active_squares = player.active_squares[square_to_delete.current_piece.name]

    player_active_squares.each_with_index do |square, i|
      if square.position == square_to_delete.position
        player_active_squares.delete(player_active_squares[i])
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

    delete_active_square(potential_opponent_pawn, @inactive_player)

    potential_opponent_pawn.current_piece = nil
  end

  def checkmate?(attackers)
    return false unless king_cannot_move?

    return true if multiple_attackers?(attackers)

    no_piece_can_interfere?(attackers)
  end

  def king_cannot_move?
    king_available_positions = @current_king.current_piece.generate_available_positions(@current_king, @inactive_player.color, @current_king)
    return true if king_available_positions.empty?

    false
  end

  def no_piece_can_interfere?(attackers)
    can_not_interfere = false
    # Gathers the interpositions between an attacker and a king
    interpositions = generate_interposition_squares(attackers.select(&:first)[0][1], @current_king)

    # Iterates through all active pieces to check whether there is intersection between piece's available positions and check's interpositions.
    @current_player.active_squares.each_value do |squares|
      can_not_interfere = iterate_through_pieces(squares, interpositions)
      break unless can_not_interfere
    end
    can_not_interfere
  end

  def multiple_attackers?(attackers)
    attackers.select(&:first).length > 1
  end

  def iterate_through_pieces(squares, interpositions)
    can_not_interfere = true
    squares.each do |square|
      next if square.current_piece.name == :king

      available_positions = square.current_piece.generate_available_positions(square, @inactive_player.color, @current_king)
      available_positions = interpositions & available_positions
      can_not_interfere = available_positions.empty? ? true : false
      break unless can_not_interfere
    end
    can_not_interfere
  end

  def promotion(board, board_renderer)
    return unless promotion_eligible?(board)

    original_cursor = [board.cursor_x, board.cursor_y]
    current_captured_piece = prepare_promotion_ui(board)
    promotion_selection(board_renderer, board, current_captured_piece)
    board.cursor_x, board.cursor_y = original_cursor
  end

  def promotion_selection(board_renderer, board, current_captured_piece)
    board_renderer.render(board, @current_player.color.to_s, @available_positions, @message)
    current_captured_piece, shift = promotion_keypress_handler(board, current_captured_piece)
    return if shift.zero?

    board.cursor_x += shift
    board.public_send("current_#{current_color}_captured_piece=", current_captured_piece)
  end

  def place_promoted_piece(board, current_captured_piece)
    delete_active_square(board.current_square, @current_player)
    board.current_square.current_piece = current_captured_piece
    @current_player.active_squares[board.current_square.current_piece.name].push(board.current_square)
    [0, 0]
  end

  def prepare_promotion_ui(board)
    board.cursor_x = 2
    board.cursor_y = @current_player.color == :White ? 1 : 11
    current_color = @current_player.color.to_s.downcase
    board.public_send("current_#{current_color}_captured_piece=", board.public_send("#{current_color}_captured_pieces"))
    @message = 'Choose a piece for promotion.'
    @available_positions = []
    board.public_send("current_#{current_color}_captured_piece")
  end

  def promotion_eligible?(board)
    [1, 8].include?(board.current_square.position[1]) &&
      !board.send("#{@current_player.color.downcase}_captured_pieces").nil?
  end

  def promotion_keypress_handler(board, current_piece)
    loop do
      case Curses.getch
      when 10
        return place_promoted_piece(board, current_piece)
      when Curses::KEY_RIGHT
        return current_piece.right_adjacent, 3 if current_piece.right_adjacent
      when Curses::KEY_LEFT
        return current_piece.left_adjacent, -3 if current_piece.left_adjacent
      end
    end
  end

  def capture_handler(board)
    last_captured_piece = board.public_send("#{@inactive_player.color.to_s.downcase}_captured_pieces")
    if last_captured_piece

      already_captured, tail = traverse_captured_list(board, last_captured_piece)

      unless already_captured
        tail.right_adjacent = board.current_square.current_piece.dup
        tail.right_adjacent.left_adjacent = tail
      end
    else
      board.public_send("#{@inactive_player.color.to_s.downcase}_captured_pieces=", board.current_square.current_piece.dup)
    end
    board.current_square.current_piece = nil
  end

  def traverse_captured_list(board, last_captured_piece)
    already_captured = false
    tail = nil
    while last_captured_piece
      if last_captured_piece.symbol == board.current_square.current_piece.symbol
        already_captured = true
        break
      else
        tail = last_captured_piece
        last_captured_piece = last_captured_piece.right_adjacent
      end
    end
    [already_captured, tail]
  end

  def update_piece_squares(square)
    active_squares_piece = @current_player.active_squares[@selected_piece.name]
    active_squares_piece.each_with_index do |figure, i|
      if figure.position == @old_square.position
        active_squares_piece[i] = square
        break
      end
    end
  end

  def castling(square)
    aux_old_square = @old_square
    aux_selected_piece = @selected_piece

    rook_source, rook_destination = get_castling_direction(square)
    rook_destination.current_piece = rook_source.current_piece
    rook_source.current_piece = nil

    new_square = rook_destination
    @old_square = rook_source

    @selected_piece = new_square.current_piece
    @selected_piece.moved = true
    update_piece_squares(new_square)
    @old_square = aux_old_square
    @selected_piece = aux_selected_piece
  end

  def get_castling_direction(square)
    square.position[0] == 'G' ? [square.right_adjacent, square.left_adjacent] : [square.left_adjacent.left_adjacent, square.right_adjacent]
  end
end