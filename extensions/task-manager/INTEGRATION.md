# Python Script Integration

## Overview

The Todo Manager extension now integrates with a sophisticated Python script (`scripts/find_todos.py`) to provide advanced TODO detection capabilities with gitignore support and intelligent categorization.

## Features

### 🔍 **Advanced TODO Detection**

- Detects multiple TODO variations: `TODO`, `Todo`, `todo`, `TO-DO`, `To-Do`, `to-do`, `FIXME`, `FIX ME`, `fix me`
- Supports various comment styles: `//`, `#`, `/* */`, `<!-- -->`, `"""`, `'''`
- Works across multiple file types: Python, JavaScript, TypeScript, HTML, CSS, Markdown, etc.

### 🚫 **Gitignore Support**

- Automatically respects `.gitignore` files in your workspace
- Uses `pathspec` library for accurate gitignore pattern matching
- Fallback to basic pattern matching if `pathspec` is not available
- Excludes common directories: `node_modules`, `.venv`, `dist`, `build`, etc.

### 🏷️ **Smart Categorization**

- **Bug**: Items containing "bug", "fix", "error", "issue"
- **Feature**: Items containing "feature", "implement", "add"
- **Refactor**: Items containing "refactor", "clean", "optimize"
- **Documentation**: Items containing "document", "docs", "comment"
- **Testing**: Items containing "test", "testing", "unit test"
- **General**: All other TODOs

### 🎨 **Visual Enhancements**

- Category-specific icons and emojis in the TODO tree
- Rich tooltips with file information and categories
- Click-to-open functionality for codebase TODOs

## How It Works

1. **Extension Activation**: When you click "Sync Todos from Codebase"
2. **Python Script Execution**: The extension spawns the Python script with `--extension-mode`
3. **JSON Output**: The script outputs structured JSON data to stdout
4. **Data Processing**: The extension parses the JSON and creates TodoItem objects
5. **UI Update**: The tree view refreshes with categorized, clickable TODOs

## Installation Requirements

### Required

- **Python 3.x**: The script requires Python 3 to run
- **VSCode**: The extension runs in Visual Studio Code

### Optional (Recommended)

- **pathspec**: For better gitignore support

  ```bash
  pip install pathspec
  ```

## Fallback Behavior

If the Python script fails to execute:

1. The extension shows a warning message
2. Falls back to the original regex-based detection
3. Continues to work with basic TODO detection (without gitignore support)

## File Structure

```
extensions/task-manager/
├── scripts/
│   └── find_todos.py          # Advanced TODO detection script
├── src/
│   ├── todoProvider.ts        # Main extension logic
│   ├── todoItem.ts           # TODO item representation
│   └── extension.ts          # Extension entry point
└── package.json              # Extension manifest
```

## Script Usage

The Python script can also be used standalone:

```bash
# Basic usage
python scripts/find_todos.py

# Specific directory
python scripts/find_todos.py /path/to/project

# Different output formats
python scripts/find_todos.py --format markdown
python scripts/find_todos.py --format json
python scripts/find_todos.py --format all

# Extension mode (JSON to stdout)
python scripts/find_todos.py --extension-mode
```

## Benefits Over Original Implementation

| Feature | Original | With Python Script |
|---------|----------|-------------------|
| TODO Variations | Limited | Comprehensive |
| Gitignore Support | ❌ | ✅ |
| File Type Support | Basic | Extensive |
| Categorization | ❌ | ✅ |
| Binary File Detection | ❌ | ✅ |
| Performance | Good | Better (filtered files) |
| Accuracy | Basic regex | Advanced patterns |

## Troubleshooting

### Python Not Found

- Ensure Python 3 is installed and in your PATH
- The extension tries both `python3` and `python` commands

### No TODOs Found

- Check if your files are being ignored by `.gitignore`
- Verify TODO format matches supported patterns
- Ensure files have supported extensions

### Performance Issues

- Install `pathspec` for better gitignore performance
- Check if large directories are being scanned unnecessarily

## Development

To modify the Python script:

1. Edit `scripts/find_todos.py`
2. Test with `--extension-mode` flag
3. Recompile the TypeScript extension: `npm run compile`
4. Reload the extension in VSCode

## Future Enhancements

- [ ] Custom TODO patterns configuration
- [ ] Workspace-specific ignore patterns
- [ ] TODO priority levels
- [ ] Integration with issue trackers
- [ ] Bulk TODO operations
