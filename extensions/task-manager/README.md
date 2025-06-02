# Todo Manager - VSCode Extension

A powerful task management extension for Visual Studio Code that helps you track todos both from your codebase and manually added tasks.

## Features

### 🔄 **Sync Todos from Codebase**

- Automatically scans your entire workspace for TODO comments
- Supports multiple comment formats:
  - `// TODO: your task`
  - `# TODO: your task`
  - `<!-- TODO: your task -->`
  - `/* TODO: your task */`
- Case-insensitive detection (TODO, todo, To-Do, etc.)
- Click on codebase todos to jump directly to the file and line

### ✏️ **Manual Todo Management**

- Add custom todos directly through the extension
- Mark todos as complete/incomplete
- Delete todos when they're no longer needed

### 💾 **Persistent Storage**

- Saves todos in a `.todo` file in your workspace
- Automatically loads todos when you open your workspace
- Preserves both manual and synced todos

### 🎨 **Clean Interface**

- Integrates seamlessly into VSCode's Explorer sidebar
- Shows completed todos with strikethrough formatting
- Different icons for complete/incomplete tasks
- Tooltips showing task details and file locations

## Usage

1. **View Todos**: Open the Explorer sidebar and look for the "TO-DO LIST" panel
2. **Sync from Codebase**: Click the sync button (🔄) to scan your code for TODO comments
3. **Add Manual Todo**: Click the add button (➕) and enter your task
4. **Mark Complete**: Click the check button (✓) next to any todo
5. **Delete Todo**: Click the trash button (🗑️) to remove a todo
6. **Jump to Code**: Click on codebase todos to open the file at the exact line

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
5. Install using `code --install-extension task-manager-0.0.1.vsix` (or your preferred IDE command)

After installation, restart your IDE and the Todo Manager will appear in your Explorer sidebar.

## File Storage

Todos are automatically saved to a `.todo` file in your workspace root. This file is in JSON format and can be committed to version control if you want to share todos with your team.

## Supported Comment Formats

The extension recognizes TODO comments in these formats:

- `// TODO: task description`
- `# TODO: task description`
- `<!-- TODO: task description -->`
- `/* TODO: task description */`

All variations are case-insensitive, so `todo`, `TODO`, `To-Do`, etc. all work.

## Commands

- `todoManager.sync` - Sync todos from codebase
- `todoManager.addTodo` - Add a new manual todo
- `todoManager.refresh` - Refresh the todo list
- `todoManager.toggleComplete` - Toggle completion status
- `todoManager.deleteTodo` - Delete a todo

## Requirements

- Visual Studio Code 1.100.0 or higher

---

**Enjoy productive task management! 🚀**
