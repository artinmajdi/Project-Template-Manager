# Todo Manager - VSCode Extension

A powerful task management extension for Visual Studio Code that helps you track todos both from your codebase and manually added tasks. **Now with advanced Python-powered TODO detection and gitignore support!**

## ✨ New Features (v0.1.0)

### 🐍 **Advanced Python Integration**

- **Gitignore Support**: Automatically respects `.gitignore` files in your workspace
- **Smart Categorization**: TODOs are automatically categorized as Bug, Feature, Refactor, Documentation, Testing, or General
- **Enhanced Detection**: Finds more TODO variations including `FIXME`, `FIX ME`, and various case combinations
- **Better Performance**: Excludes binary files and respects ignore patterns
- **Visual Enhancements**: Category-specific icons and emojis in the TODO tree

## Features

### 🔄 **Sync Todos from Codebase**

- **Advanced Detection**: Uses a sophisticated Python script for comprehensive TODO scanning
- **Gitignore Aware**: Automatically excludes files and directories listed in `.gitignore`
- **Multiple Formats**: Supports extensive comment formats:
  - `// TODO: your task`
  - `# TODO: your task`
  - `<!-- TODO: your task -->`
  - `/* TODO: your task */`
  - `""" TODO: your task """`
  - And many more variations including `FIXME`, `FIX ME`
- **Smart Categorization**: Automatically categorizes TODOs based on keywords:
  - 🐛 **Bug**: Contains "bug", "fix", "error", "issue"
  - ✨ **Feature**: Contains "feature", "implement", "add"
  - ♻️ **Refactor**: Contains "refactor", "clean", "optimize"
  - 📚 **Documentation**: Contains "document", "docs", "comment"
  - 🧪 **Testing**: Contains "test", "testing", "unit test"
  - 📝 **General**: All other TODOs
- **File Type Support**: Works across Python, JavaScript, TypeScript, HTML, CSS, Markdown, and many more
- **Click to Navigate**: Jump directly to the file and line where the TODO is located

### ✏️ **Manual Todo Management**

- Add custom todos directly through the extension
- Mark todos as complete/incomplete
- Delete todos when they're no longer needed

### 💾 **Persistent Storage**

- Saves todos in a `.todo` file in your workspace
- Automatically loads todos when you open your workspace
- Preserves both manual and synced todos

### 🎨 **Enhanced Interface**

- Category-specific icons and emojis for visual distinction
- Rich tooltips showing category, file location, and context
- Strikethrough formatting for completed todos
- Seamless integration into VSCode's Explorer sidebar

## Installation Requirements

### Required

- **Visual Studio Code** 1.96.0 or higher
- **Python 3.x** for advanced TODO detection

### Optional (Recommended)

- **pathspec library**: For better gitignore support

  ```bash
  pip install pathspec
  ```

## Installation

### Using the Project Installation Script (Recommended)

1. From the project root directory, run:

   ```bash
   ./install_extension.sh
   ```

2. Select "task-manager" from the list of available extensions
3. Choose your preferred IDE (VSCode, Cursor, Windsurf, etc.)
4. Choose "Package and install locally"
5. The extension will be automatically built and installed

### Manual Installation

1. Navigate to the `extensions/task-manager` directory
2. Run `npm install` to install dependencies
3. Run `npm run compile` to compile TypeScript
4. Run `vsce package` to create the .vsix file
5. Install using `code --install-extension task-manager-0.1.0.vsix`

After installation, restart your IDE and the Todo Manager will appear in your Explorer sidebar.

## Usage

1. **View Todos**: Open the Explorer sidebar and look for the "TO-DO LIST" panel
2. **Sync from Codebase**: Click the sync button (🔄) to scan your code for TODO comments
   - First attempt uses the advanced Python script with gitignore support
   - Falls back to basic regex detection if Python is unavailable
3. **Add Manual Todo**: Click the add button (➕) and enter your task
4. **Mark Complete**: Click the check button (✓) next to any todo
5. **Delete Todo**: Click the trash button (🗑️) to remove a todo
6. **Jump to Code**: Click on codebase todos to open the file at the exact line

## Advanced Features

### Gitignore Integration

The extension automatically respects your `.gitignore` file, excluding:

- Files and directories listed in `.gitignore`
- Common build artifacts (`dist/`, `build/`, `node_modules/`)
- Virtual environments (`.venv/`, `venv/`)
- IDE-specific files (`.vscode/`, `.idea/`)

### Fallback Behavior

If Python is not available or the advanced script fails:

- Shows a helpful warning message
- Automatically falls back to basic regex-based detection
- Continues to work with reduced functionality

## File Storage

Todos are automatically saved to a `.todo` file in your workspace root. This file is in JSON format and can be committed to version control if you want to share todos with your team.

## Supported Comment Formats

The extension recognizes TODO comments in these formats and many more:

- `// TODO: task description`
- `# TODO: task description`
- `<!-- TODO: task description -->`
- `/* TODO: task description */`
- `""" TODO: task description """`
- `''' TODO: task description '''`
- `// FIXME: fix this issue`
- `# FIX ME: needs attention`

All variations are case-insensitive, so `todo`, `TODO`, `To-Do`, `FIXME`, etc. all work.

## Commands

- `todoManager.sync` - Sync todos from codebase (with advanced Python detection)
- `todoManager.addTodo` - Add a new manual todo
- `todoManager.refresh` - Refresh the todo list
- `todoManager.toggleComplete` - Toggle completion status
- `todoManager.deleteTodo` - Delete a todo

## Troubleshooting

### Python Not Found

- Ensure Python 3 is installed and in your PATH
- The extension tries both `python3` and `python` commands
- Install the optional `pathspec` library for better performance

### No TODOs Found

- Check if your files are being ignored by `.gitignore`
- Verify TODO format matches supported patterns
- Ensure files have supported extensions

For more detailed information, see [INTEGRATION.md](./INTEGRATION.md).

---

**Enjoy productive task management with advanced TODO detection! 🚀**
