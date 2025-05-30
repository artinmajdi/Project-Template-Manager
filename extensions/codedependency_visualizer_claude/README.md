# Code Dependency Visualizer

A VS Code extension that visualizes code dependencies as an interactive graph. It analyzes import statements in Python, JavaScript, and TypeScript files to build a dependency graph.

## Features

- **Multi-language support**: Analyzes Python, JavaScript, and TypeScript files
- **Interactive graph visualization**: Powered by D3.js with zoom, pan, and drag capabilities
- **Smart import resolution**: Handles relative and absolute imports
- **Gitignore support**: Respects .gitignore patterns to exclude unwanted files
- **Entry point selection**: Multiple ways to select the starting point for analysis

## Usage

1. Open a workspace in VS Code
2. Run one of the following commands:
   - **"Show Code Dependency Graph"** - Analyze dependencies from a selected entry point
   - **"Analyze Dependencies for Current File"** - Analyze dependencies starting from the currently open file

### Entry Point Selection

When using "Show Code Dependency Graph", you can select the entry point in three ways:
- Use the currently open file
- Browse and select a file
- Enter the path manually

## Graph Visualization

The dependency graph shows:
- **Nodes**: Represent files in your project
  - Blue nodes: Python files
  - Yellow nodes: JavaScript files
  - Blue (darker) nodes: TypeScript files
  - Red border: Entry point file
- **Edges**: Arrows showing import relationships
- **Controls**: Reset zoom, center graph, toggle labels

## Supported Import Patterns

### Python
- `import module`
- `from module import something`
- Package imports with `__init__.py`

### JavaScript/TypeScript
- ES6 imports: `import ... from 'module'`
- CommonJS: `require('module')`
- Relative imports: `./module`, `../module`

## Development

To set up the development environment:

1. Clone the repository
2. Run `npm install`
3. Run `npm run compile` to build
4. Press F5 in VS Code to launch a new instance with the extension

## License

ISC