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
  include MovementRules
  include InterpositionGenerator


  def initialize
    @current_player = 'White'
    @inactive_player = 'Black'
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
        current_king = instance_variable_get("@#{@current_player.downcase}_player").active_squares[:king].first

        # Renders the board to the terminal.
        board_renderer.render(board, @current_player, @available_positions, @message, [@white_player.captured_pieces, @black_player.captured_pieces])

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

          # Checks whether king is checked and whether current player selects non-king piece.
          if is_king_checked[0] && Object.const_get("#{@current_player}_FIGURES_FOR_CHECK").include?(board.current_square.current_piece) && @clipboard_figure.nil?

            # Filters out the array of king's checks to keep only the squares from which the king is checked.
            attacker = is_king_checked[1].select { |subarray| subarray.first == true }

            # Checks if a king is checked by only one piece, since if it is a double-check, only the king movement is allowed.
            # The following block generates movable positions if a selected piece can interrupt the check.
            if attacker.length == 1 && attacker.first.length == 2

              # Retrieves and stores the hash of player's pieces.
              current_player_pieces = instance_variable_get("@#{@current_player.downcase}_player").active_squares

              # Generates positions between an attacker and king, including attacker's square.
              interpositions = generate_interposition_squares(attacker[0][1], current_king)

              # Generates possible positions (for the selected piece) that would interrupt the check.
              generate_movable_positions(interpositions, current_player_pieces, board.current_square)
            end

          # The following block will be executed if king is not checked, and current player's piece is selected.
          # It generates available positions for selected piece.
          elsif @clipboard_figure.nil? && Object.const_get("#{@current_player.upcase}_FIGURES").values.include?(board.current_square.current_piece)
            @clipboard_figure = board.current_square.current_piece
            case @clipboard_figure
            when '♙', '♟'
              @available_positions = MOVEMENT_RULES[:pawn].call(board.current_square)
            when '♖', '♜'
              @available_positions = MOVEMENT_RULES[:rook].call(board.current_square, @inactive_player, DIRECTIONS)
            when '♞', '♘'
              @available_positions = MOVEMENT_RULES[:knight].call(board.current_square, @inactive_player, DIRECTIONS)
            when '♗', '♝'
              @available_positions = MOVEMENT_RULES[:bishop].call(board.current_square, @inactive_player, BISHOP_DIRECTIONS)
            when '♛', '♕'
              @available_positions = MOVEMENT_RULES[:rook].call(board.current_square, @inactive_player, DIRECTION_RULES[:queen])
            when '♔', '♚'
              @available_positions = MOVEMENT_RULES[:king].call(board.current_square, @inactive_player, DIRECTION_RULES[:queen])
            end
            @old_square = board.current_square
            @message = 'Press "u" if you want to unselect currently selected piece.'

          # The following block moves selected piece and captures the opponent's piece if it occupies selected square.
          elsif @available_positions.include?(board.current_square.position) && !@clipboard_figure.nil?

            # Retrieves player's objects to access them later to update piece's positions
            player = instance_variable_get("@#{@current_player.downcase}_player")
            opponent = instance_variable_get("@#{@inactive_player.downcase}_player")

            # Checks whether selected square is occupied by opponent's piece and deletes (captures) it if it is.
            if Object.const_get("#{@inactive_player.upcase}_FIGURES").include?(board.current_square.current_piece)

              player.captured_pieces.push(board.current_square.current_piece)
              opponent_squares_piece = opponent.active_squares[PIECE_UNICODE[@inactive_player.to_sym].key(board.current_square.current_piece)]

              opponent_squares_piece.each_with_index do |piece, i|
                if piece.position == board.current_square.position
                  opponent_squares_piece.delete(opponent_squares_piece[i])
                  break
                end
              end
            end

            # Puts player's selected piece onto the selected square.
            board.current_square.current_piece = @clipboard_figure

            update_piece_squares(player, board)

            # Reseting everything to nil for the next move.
            @clipboard_figure = nil
            @old_square.current_piece = nil
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

        # Checks whether current king is checked.
        is_king_checked = check_checkup(current_king)
        @message = 'The king is checked.' if is_king_checked[0]
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
    king_checked_rook = king_checked?(current_king, @inactive_player, DIRECTIONS, 'rook')
    king_checked_bishop = king_checked?(current_king, @inactive_player, BISHOP_DIRECTIONS, 'bishop')
    king_checked_queen = king_checked?(current_king, @inactive_player, DIRECTION_RULES[:queen], 'queen')
    king_checked_knight = attacked_by_knight?(current_king, @inactive_player)
    king_checked_pawn = attacked_by_pawn?(current_king, @inactive_player)

    is_king_checked = king_checked_queen[0] || king_checked_rook[0] || king_checked_bishop[0] || king_checked_knight[0] || king_checked_pawn[0]
    [is_king_checked, [king_checked_rook, king_checked_bishop, king_checked_knight, king_checked_pawn, king_checked_queen]]
  end

  # Toggles the current's player color.
  def toggle_current_player
    if @current_player == 'White'
      @current_player = 'Black'
      @inactive_player = 'White'
    else
      @current_player = 'White'
      @inactive_player = 'Black'
    end
  end

  # Updates the player's piece and its new square.
  def update_piece_squares(player, board)
    case @clipboard_figure
    when '♛', '♕'
      player.active_squares[:queen] = [board.current_square]
    when '♔', '♚'
      player.active_squares[:king] = [board.current_square]
    else
      active_squares_piece = player.active_squares[PIECE_UNICODE[@current_player.to_sym].key(@clipboard_figure)]
      active_squares_piece.each_with_index do |figure, i|
        if figure.position == @old_square.position
          active_squares_piece[i] = board.current_square
          break
        end
      end
    end
  end

  # Generates available positions for a selected non-king piece in the case of a check.
  def generate_movable_positions(interpositions, player_pieces_object, current_square)
    result = []
    key = PIECE_UNICODE[@current_player.to_sym].key(current_square.current_piece)
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
end
