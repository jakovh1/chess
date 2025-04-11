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
    @current_player = :White
    @inactive_player = :Black
    @winner = nil
    @clipboard_figure = nil
    @old_square = nil
    @new_square = nil
    @available_positions = []
    @white_player = Player.new('white')
    @black_player = Player.new('black')
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
        current_king = instance_variable_get("@#{@current_player.to_s.downcase}_player").active_squares[:king].first

        # Checks whether current king is checked.
        is_king_checked = check_checkup(current_king)
        @message = 'The king is checked.' if is_king_checked[0]

        # Renders the board to the terminal.
        board_renderer.render(board, @current_player, @available_positions, @message)

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
          if @clipboard_figure.nil? && current_piece&.color == @current_player

            @available_positions = current_piece.generate_available_positions(board.current_square, @inactive_player)
            filter_available_positions(board, current_king) if current_piece.name != :king
            unless @available_positions.empty?

              @clipboard_figure = current_piece
              @old_square = board.current_square
              @message = 'Press "u" if you want to unselect currently selected piece.'
            end

          # The following block moves selected piece and captures the opponent's piece if it occupies selected square.
          elsif @available_positions.include?(board.current_square.position) # && !@clipboard_figure.nil?

            # Retrieves player's objects to access them later to update piece's positions
            player = instance_variable_get("@#{@current_player.to_s.downcase}_player")
            opponent = instance_variable_get("@#{@inactive_player.to_s.downcase}_player")

            # Checks whether selected square is occupied by opponent's piece and deletes (captures) it if it is.
            if @inactive_player == current_piece&.color && current_piece.name != :king
              capture_handler(board) if current_piece.name != :pawn

              opponent_squares_piece = opponent.active_squares[PIECE_UNICODE[@inactive_player.to_sym].key(board.current_square.current_piece.symbol)]

              opponent_squares_piece.each_with_index do |piece, i|
                if piece.position == board.current_square.position
                  opponent_squares_piece.delete(opponent_squares_piece[i])
                  break
                end
              end
            end

            # Puts player's selected piece onto the selected square.
            board.current_square.current_piece = @clipboard_figure

            if board.current_square.current_piece.is_a?(Pawn) && (board.current_square.position[1] - @old_square.position[1]).abs == 2
              board.current_square.current_piece.en_passant_target = true
              player.recently_moved_pawn = board.current_square.current_piece
            end
            @old_square.current_piece = nil
            # En passant capture handler
            if board.current_square.current_piece.is_a?(Pawn)
              
              if @current_player == :White
                if board.current_square.bottom_adjacent.current_piece.is_a?(Pawn) && board.current_square.bottom_adjacent.current_piece.en_passant_target& 
                  opponent_squares_piece = opponent.active_squares[:pawn]

                  opponent_squares_piece.each_with_index do |piece, i|
                    if piece.position == board.current_square.bottom_adjacent.position
                      opponent_squares_piece.delete(opponent_squares_piece[i])
                      break
                    end
                  end

                  board.current_square.bottom_adjacent.current_piece = nil
                elsif board.current_square.position[1] == 8
                  aux_cursor_x = board.cursor_x
                  aux_cursor_y = board.cursor_y
                  board.cursor_x = 2
                  board.cursor_y = 1
                  board.current_white_captured_piece = board.white_captured_pieces
                  @message = 'Choose a piece for promotion.'
                  @available_positions = []
                  board_renderer.render(board, @current_player, @available_positions, @message)
                  loop do
                    case Curses.getch
                    when Curses::KEY_RIGHT
                      if board.cursor_x <= 20 && board.current_white_captured_piece.right_adjacent
                        board.cursor_x += 3
                        board.current_white_captured_piece = board.current_white_captured_piece.right_adjacent
                      end
                    when Curses::KEY_LEFT
                      if board.cursor_x >= 5 && board.current_white_captured_piece.left_adjacent
                        board.cursor_x -= 3
                        board.current_white_captured_piece = board.current_white_captured_piece.left_adjacent
                      end
                    when 10
                      board.current_square.current_piece = board.current_white_captured_piece
                      board.cursor_x = aux_cursor_x
                      board.cursor_y = aux_cursor_y
                      break
                    end
                    board_renderer.render(board, @current_player, @available_positions, @message)
                  end
                end
              elsif @current_player == :Black
                aux_cursor_x = board.cursor_x
                aux_cursor_y = board.cursor_y
                if board.current_square.top_adjacent.current_piece.is_a?(Pawn) && board.current_square.top_adjacent.current_piece.en_passant_target
                  opponent_squares_piece = opponent.active_squares[:pawn]

                  opponent_squares_piece.each_with_index do |piece, i|
                    if piece.position == board.current_square.top_adjacent.position
                      opponent_squares_piece.delete(opponent_squares_piece[i])
                      break
                    end
                  end

                  board.current_square.top_adjacent.current_piece = nil
                elsif board.current_square.position[1] == 1
                  aux_cursor_x = board.cursor_x
                  aux_cursor_y = board.cursor_y
                  board.cursor_x = 2
                  board.cursor_y = 11
                  board.current_black_captured_piece = board.black_captured_pieces
                  @message = 'Choose a piece for promotion.'
                  @available_positions = []
                  board_renderer.render(board, @current_player, @available_positions, @message)
                  loop do
                    case Curses.getch
                    when Curses::KEY_RIGHT
                      if board.cursor_x <= 20 && board.current_black_captured_piece.right_adjacent
                        board.cursor_x += 3
                        board.current_black_captured_piece = board.current_black_captured_piece.right_adjacent
                      end
                    when Curses::KEY_LEFT
                      if board.cursor_x >= 5 && board.current_black_captured_piece.left_adjacent
                        board.cursor_x -= 3
                        board.current_black_captured_piece = board.current_black_captured_piece.left_adjacent
                      end
                    when 10
                      board.current_square.current_piece = board.current_black_captured_piece
                      board.cursor_x = aux_cursor_x
                      board.cursor_y = aux_cursor_y
                      break
                    end
                    board_renderer.render(board, @current_player, @available_positions, @message)
                  end
                end
              end
            end

            # Handles the castling
            if board.current_square.current_piece.name == :king && board.current_square.current_piece.moved == false
              castling_handler(board, player) if %[C G].include?(board.current_square.position[0])
              board.current_square.current_piece.moved = true
            end

            update_piece_squares(player, board.current_square)

            # if !player.active_squares[:king][1] && %w[A H].include?(@old_square.position[0]) && !player.public_send("#{@old_square.position[0].downcase}_rook_moved") && ['♖', '♜'].include?(@clipboard_figure)
            #   player.public_send("#{@old_square.position[0].downcase}_rook_moved=", true)
            # end
            if opponent.recently_moved_pawn
              opponent.recently_moved_pawn.en_passant_target = false
              opponent.recently_moved_pawn = nil
            end

            # Reseting everything to nil for the next move.
            @clipboard_figure = nil
            #@old_square.current_piece = nil
            toggle_current_player
            @available_positions = []
            @message = nil
          end

        # The following block unselects selected piece.
        when 'u', 'U'
          @clipboard_figure = nil
          @available_positions = []
          @old_square = nil
          @message = nil

        # Terminates the game.
        when 'q', 'Q'
          break
        end
      end
    ensure
      Curses.clear
      Curses.refresh
      Curses.close_screen
    end
    Curses.close_screen
  end

  private

  # Checks whether king is checked and returns the square which checks the king.
  def check_checkup(current_king)
    king_checked_rook = king_checked?(current_king, @inactive_player, ORTHOGONAL_DIRECTIONS, 'rook')
    king_checked_bishop = king_checked?(current_king, @inactive_player, DIAGONAL_DIRECTIONS, 'bishop')
    king_checked_queen = king_checked?(current_king, @inactive_player, ORTHOGONAL_DIRECTIONS + DIAGONAL_DIRECTIONS, 'queen')
    king_checked_knight = attacked_by_knight?(current_king, @inactive_player)
    king_checked_pawn = attacked_by_pawn?(current_king, @inactive_player)

    is_king_checked = king_checked_queen[0] || king_checked_rook[0] || king_checked_bishop[0] || king_checked_knight[0] || king_checked_pawn[0]
    [is_king_checked, [king_checked_rook, king_checked_bishop, king_checked_knight, king_checked_pawn, king_checked_queen]]
  end

  def capture_handler(board)
    last_captured_piece = board.public_send("#{@inactive_player.to_s.downcase}_captured_pieces")
    if last_captured_piece
      last_captured_piece = last_captured_piece.right_adjacent until last_captured_piece.right_adjacent.nil?
      #File.open("log.txt", "a") { |file| file.puts(last_captured_piece.symbol) }
      last_captured_piece.right_adjacent = board.current_square.current_piece
      last_captured_piece.right_adjacent.left_adjacent = last_captured_piece
    else
      board.public_send("#{@inactive_player.to_s.downcase}_captured_pieces=", board.current_square.current_piece)
      #File.open("log.txt", "a") { |file| file.puts(board.public_send("#{@inactive_player.to_s.downcase}_captured_pieces").current_piece.symbol) }
    end
  end

  # Toggles the current's player color.
  def toggle_current_player
    if @current_player == :White
      @current_player = :Black
      @inactive_player = :White
    else
      @current_player = :White
      @inactive_player = :Black
    end
  end

  # Updates the player's piece and its new square.
  def update_piece_squares(player, square)
    case @clipboard_figure
    when '♛', '♕'
      player.active_squares[:queen] = [square]
    when '♔', '♚'
      player.active_squares[:king][0] = square
      #player.active_squares[:king][1] = true unless player.active_squares[:king][1]
    else
      active_squares_piece = player.active_squares[@clipboard_figure.name]
      active_squares_piece.each_with_index do |figure, i|
        if figure.position == @old_square.position
          active_squares_piece[i] = square
          break
        end
      end
    end
  end

  # Generates available positions for a selected non-king piece in the case of a check.
  def generate_movable_positions(interpositions, player_pieces_object, current_square)
    result = []
    key = current_square.current_piece.name
    directions = DIRECTION_RULES[key]
    player_pieces_object[key].each do |figure|
      if current_square.position == figure.position
        available_positions = key != :pawn ? MOVEMENT_RULES[key].call(figure, @inactive_player, directions) : MOVEMENT_RULES[key].call(figure)
        result = interpositions & available_positions
      end
    end
    if result.empty?
      @message = 'Unavailable piece was selected.'
    else
      @available_positions = result
      @clipboard_figure = current_square.current_piece
      @old_square = current_square
      @message = 'Press "u" if you want to unselect currently selected piece'
    end
  end

  # Handles the castling
  def castling_handler(board, player)
    new_square = nil
    aux_old_square = @old_square
    aux_clipboard_figure = @clipboard_figure
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
    @clipboard_figure = new_square.current_piece
    update_piece_squares(player, new_square)
    @old_square = aux_old_square
    @clipboard_figure = aux_clipboard_figure
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