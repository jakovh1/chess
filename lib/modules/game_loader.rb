# frozen_string_literal: true

module GameLoader
  SAVE_DIR = './lib/saves'

  def contains_saved_games?
    pattern = /\A\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}\.marshal\z/
    return false unless Dir.exist?(SAVE_DIR)

    Dir.entries(SAVE_DIR).any? { |filename| filename.match?(pattern) }
  end

  def load_game(filename)
    data = nil
    File.open("#{SAVE_DIR}/#{filename}", 'rb') do |file|
      data = Marshal.load(file)
    end

    data
  end

  def game_selection(saves, renderer)
    current_row = 0
    saves_length = saves.length
    loop do
      renderer.render_load_menu(saves, current_row)
      case Curses.getch
      when Curses::KEY_UP
        current_row -= 1 if current_row.positive?
      when Curses::KEY_DOWN
        current_row += 1 if current_row < saves_length - 1
      when 10
        return saves[current_row]
      when 'q', 'Q'
        return nil
      end
    end
  end

  def get_saved_games
    Dir.children(SAVE_DIR)
  end

end