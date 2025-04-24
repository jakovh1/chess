# ♟️ Chess

## 🛠️ Installation
0. Make sure that Ruby and Bundler are installed.
1. Install dependencies:
   ```bash
   bundle install
   ```
2. Clone the repository:
   ```bash
   git clone https://github.com/jakovh1/chess.git
   ```
3. Enter the project directory:
   ```bash
   cd chess
   ```
4. Run the game:
   ```bash
   ruby main.rb
   ```

## 🎮 How To Play
- Use arrow keys to move the cursor.
- Press <kbd>Enter</kbd> to select a piece.
- Press <kbd>Enter</kbd> to place a piece on the current square.
- Press <kbd>u</kbd> to unselect a piece.
- Press <kbd>s</kbd> to save the game.
- Press <kbd>l</kbd> to load the game.
- Press <kbd>q</kbd> to quit.

## 💾 Saving and Loading
- Saved games are stored in the `lib/saves/` directory.
- Saved games use a timestamped `.marshal` format.
- Load menu allows you to select a save file using arrow keys and <kbd>Enter</kbd>.

## 📁 Project Structure
chess/
├── Gemfile
├── Gemfile.lock
├── lib/
│   ├── board.rb
│   ├── board_renderer.rb
│   ├── constants/
│   ├── game.rb
│   ├── modules/
│   ├── pieces/
│   ├── player.rb
│   ├── saves/
│   └── square.rb
├── main.rb
└── README.md

## 🧠 Features
- Full chess logic: check, checkmate, stalemate, draw
- Captured pieces display, piece promotion UI
- Save/Load funcitonality
- Keyboard-based navigation (Curses)
- 2-player mode

## 🚧 Future Improvements
- Timer support

## 📄 License
[MIT](https://www.mit.edu/~amini/LICENSE.md)

