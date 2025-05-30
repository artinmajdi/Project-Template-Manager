# Code Dependency Visualizer

A VS Code extension that visualizes Python code dependencies as an interactive graph.

## Features

- **Accurate Python Analysis**: Uses a robust Python script to analyze imports and dependencies
- **Interactive Graph**: Navigate through your codebase dependencies with an interactive D3.js visualization
- **Depth Control**: Adjust the analysis depth to focus on immediate dependencies or explore deeper relationships
- **Entry Point Selection**: Choose any Python file as the starting point for analysis
- **Git-aware**: Respects .gitignore patterns and excludes irrelevant files

## Requirements

- **Python 3**: The extension requires Python 3 to be installed and available in your PATH
- **VS Code 1.96.0+**

## Usage

1. Open a Python project in VS Code
2. Use Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and run:
   - `Show Code Dependency Graph` - Analyze dependencies starting from a selected entry point
   - `Analyze Dependencies for Current File` - Analyze dependencies for the currently open file

3. Select your entry point file when prompted
4. Choose the analysis depth (number of dependency levels to explore)
5. Interact with the generated graph:
   - **Drag** nodes to reposition them
   - **Zoom** in/out with mouse wheel
   - **Hover** over nodes to see full file paths
   - Use **controls** to reset zoom, center graph, or toggle labels

## Graph Features

- **Entry Point**: Highlighted with a red border and larger size
- **Node Colors**: Different colors for Python files (blue)
- **Dependencies**: Arrows show import relationships
- **Depth Control**: Real-time adjustment of analysis depth

## Technical Details

This extension uses a sophisticated Python script (`find_unused_files.py`) that:
- Parses Python AST to accurately identify imports
- Handles relative and absolute imports
- Respects gitignore patterns
- Provides comprehensive dependency analysis

## Troubleshooting

**"Python not found" error**: Ensure Python 3 is installed and available in your system PATH. The extension tries both `python3` and `python` commands.

**Empty graph**: Make sure your entry point file exists and has dependencies within your project. Standard library imports are not shown.

## Version History

### 1.0.0
- Major rewrite to use Python-based dependency analysis
- Significantly improved accuracy for Python imports
- Better handling of relative imports and package structures
- Enhanced graph visualization and controls
