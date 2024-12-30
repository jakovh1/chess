# frozen_string_literal: true

FigureDictionary = Struct.new(:pawn, :rook, :knight, :bishop, :queen, :king)

WHITE_FIGURES = FigureDictionary.new('♙', '♖', '♘', '♗', '♕', '♔')
BLACK_FIGURES = FigureDictionary.new('♟', '♜', '♞', '♝', '♛', '♚')
