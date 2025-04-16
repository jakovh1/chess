# frozen_string_literal: true

module InterpositionGenerator
  def generate_interposition_squares(attacking_square, king_square)
    case attacking_square.current_piece.name
    when :rook
      interposition_squares = attacking_rook(attacking_square, king_square)
    when :bishop
      interposition_squares = attacking_bishop(attacking_square, king_square)
    when :queen
      interposition_squares = attacking_square.position[0] == king_square.position[0] || attacking_square.position[1] == king_square.position[1] ? attacking_rook(attacking_square, king_square) : attacking_bishop(attacking_square, king_square)
    when :knight
      interposition_squares = [attacking_square.position]
    when :pawn
      interposition_squares = [attacking_square.position]
    end
    interposition_squares
  end
  
  # Generates interposition squares between king and a rook.
  def attacking_rook(attacking_square, king_square)
    result = []

    # If a rook and a king are on the same file (column),
    # it generates an array between their ranks
    # and iterates through a created array to push positions,
    # composed of the shared file and ranks between.
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
        result.push([f, king_square.position[1]])
      end
    end
    result.delete(king_square.position)
    result
  end
  
  # Generates interposition squares between king and a bishop.
  def attacking_bishop(attacking_square, king_square)
    result = []

    # Determines the files' min and max which will be used for 'between_files' array generation.
    min_file, max_file = [attacking_square.position[0], king_square.position[0]].sort

    # Turns the range between min_file and max_file to an array.
    between_files = (min_file..max_file).to_a

    # Determines the ranks' min and max which will be used for 'between_ranks' array generation.
    min_rank, max_rank = [attacking_square.position[1], king_square.position[1]].sort

    # Turns the range between min_rank and max_rank to an array.
    between_ranks = (min_rank..max_rank).to_a

    # If neither the attacking bishop nor the checked king is positioned on both the lowest file and the lowest rank,
    # then one of them must be on the lowest file and the highest rank.
    unless [attacking_square.position, king_square.position].include?([between_files[0], between_ranks[0]])
      between_ranks.reverse!
    end

    # Iterates through files and ranks as they are now properly sorted and pushes each iteration (position) into the result array.
    between_ranks.each_with_index do |r, i|
      result.push([between_files[i], r])
    end

    # Deletes king's position from the array as it is unnecessary.
    result.delete(king_square.position)
    result
  end
end
