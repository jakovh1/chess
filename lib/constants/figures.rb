# frozen_string_literal: true

FigureDictionary = Struct.new(:pawn, :rook, :knight, :bishop, :queen, :king)

WHITE_FIGURES = FigureDictionary.new('♙', '♖', '♘', '♗', '♕', '♔')
BLACK_FIGURES = FigureDictionary.new('♟', '♜', '♞', '♝', '♛', '♚')

Black_FIGURES_FOR_CHECK = ['♟', '♜', '♞', '♝', '♛'].freeze
White_FIGURES_FOR_CHECK = ['♙', '♖', '♘', '♗', '♕'].freeze

PIECE_UNICODE = {
  White: {
    rook:   '♖',
    knight: '♘',
    bishop: '♗',
    queen:  '♕',
    pawn:   '♙',
    king:   '♔'
  },
  Black: {
    rook:   "♜",
    knight: '♞',
    bishop: '♝',
    queen:  '♛',
    pawn:   '♟',
    king:   '♚'
  }
}.freeze
