# frozen_string_literal: true

require 'curses'

require_relative './board'
require_relative './board_renderer'
require_relative './player'
require_relative './constants/figures'
require_relative './constants/movement_rules'
require_relative './constants/directions'

class Game
  include Curses
  include MovementRules


  def initialize
    @current_player = 'White'
    @inactive_player = 'Black'
    @winner = nil
    @clipboard_figure = nil
    @old_square = nil
    @new_square = nil
    @available_positions = nil
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
      # assign_king_squares(board.board)
      loop do
        current_king = instance_variable_get("@#{@current_player.downcase}_player").active_squares[:king].first
        king_checked_rook = king_checked?(current_king, @inactive_player, DIRECTIONS, 'rook')
        king_checked_bishop = king_checked?(current_king, @inactive_player, BISHOP_DIRECTIONS, 'bishop')
        king_checked_queen = king_checked?(current_king, @inactive_player, DIRECTIONS + BISHOP_DIRECTIONS, 'queen')
        king_checked_knight = legal_by_knight?(current_king, @inactive_player)
        king_checked_pawn = legal_by_pawn?(current_king, @inactive_player)

        is_king_checked = king_checked_queen[0] || king_checked_rook[0] || king_checked_bishop[0] || king_checked_knight[0] || king_checked_pawn[0]

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
          if is_king_checked && @clipboard_figure.nil?
            check_array = [king_checked_bishop, king_checked_knight, king_checked_pawn, king_checked_queen, king_checked_rook]
            current_player_pieces = instance_variable_get("@#{@current_player.downcase}_player").active_squares

            attacker = check_array.select { |subarray| subarray.first == true }
            if attacker.length == 1 && attacker.first.length == 2
              interpositions = generate_interposition_squares(attacker[0][1], current_king)
              set_movable_positions(interpositions, current_player_pieces)
              unless board.current_square.current_piece.nil?
                pieces = Object.const_get("#{@current_player.upcase}_FIGURES").values
                if pieces.include?(board.current_square.current_piece)
                  if ['♔', '♚'].include?(board.current_square.current_piece)
                    @clipboard_figure = board.current_square.current_piece
                    @available_positions = MOVEMENT_RULES[:king].call(board.current_square, @inactive_player, DIRECTIONS + BISHOP_DIRECTIONS)
                  else
                    figure = current_player_pieces[PIECE_UNICODE[@current_player.to_sym].key(board.current_square.current_piece)]
                    #File.open("log.txt", "a") { |file| file.puts(figure.inspect) }
                    figure.each do |square|
                      if square.position == board.current_square.position && !square.movable.empty?
                        @clipboard_figure = board.current_square.current_piece
                        @available_positions = square.movable
                        break
                      end
                    end
                  end
                  
                  @old_square = board.current_square
                  @message = 'Press "u" if you want to unselect currently selected piece'
                end
              end
            end

          elsif @clipboard_figure.nil?
            unless board.current_square.current_piece.nil?
              pieces = Object.const_get("#{@current_player.upcase}_FIGURES").values
              if pieces.include?(board.current_square.current_piece)
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
                  @available_positions = MOVEMENT_RULES[:rook].call(board.current_square, @inactive_player, DIRECTIONS) +
                                         MOVEMENT_RULES[:bishop].call(board.current_square, @inactive_player, BISHOP_DIRECTIONS)
                when '♔', '♚'
                  @available_positions = MOVEMENT_RULES[:king].call(board.current_square, @inactive_player, DIRECTIONS + BISHOP_DIRECTIONS)
                end
                @old_square = board.current_square
                @message = 'Press "u" if you want to unselect currently selected piece'
              end
            end
          else
            if @available_positions.include?(board.current_square.position)
              player = instance_variable_get("@#{@current_player.downcase}_player")
              opponent = instance_variable_get("@#{@inactive_player.downcase}_player")
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
              board.current_square.current_piece = @clipboard_figure
              update_piece_squares(player, board)

              @clipboard_figure = nil
              @old_square.current_piece = nil
              toggle_current_player
              @available_positions = nil
              @message = nil
            end
          end
        when 'u', 'U'
          @clipboard_figure = nil
          @available_positions = nil
          @old_square = nil
          @message = nil
        when 'q', 'Q'
          break
        end

        board_renderer.render(board, @current_player, @available_positions, @message, [@white_player.captured_pieces, @black_player.captured_pieces])
      end
    ensure
      Curses.clear
      Curses.refresh
      Curses.close_screen
    end
    Curses.close_screen
  end

  private

  def toggle_current_player
    if @current_player == 'White'
      @current_player = 'Black'
      @inactive_player = 'White'
    else
      @current_player = 'White'
      @inactive_player = 'Black'
    end
  end

  # def assign_king_squares(board)
  #   cursor = board
  #   cursor = cursor.right_adjacent until cursor.position == ['E', 1]
  #   @white_player.king_square = cursor

  #   cursor = cursor.top_adjacent until cursor.position == ['E', 8]
  #   @black_player.king_square = cursor
  # end

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

  def set_movable_positions(interpositions, player_pieces_object)
    movable_pieces = []
    player_pieces_object.each_key do |key|
      directions = DIRECTION_RULES[key]
      player_pieces_object[key].each_with_index do |square, i|
        available_positions = key != :pawn ? MOVEMENT_RULES[key].call(square, @inactive_player, directions) : MOVEMENT_RULES[key].call(square)
        player_pieces_object[key][i].movable = interpositions & available_positions
        movable_pieces.push(square.position) unless player_pieces_object[key][i].movable.empty?
      end
    end
    movable_pieces
  end

end
