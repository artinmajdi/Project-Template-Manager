# Code Dependency Visualizer

A powerful VS Code extension that visualizes Python code dependencies as an interactive, hierarchical graph using advanced AST-based analysis.

![Extension Preview](https://via.placeholder.com/800x400/2d3748/white?text=Interactive+Dependency+Graph)

## 🚀 Features

### Core Functionality
- **🔍 Accurate Python Analysis**: Uses sophisticated Python AST parsing to analyze imports and dependencies
- **📊 Interactive Hierarchical Graph**: Clean left-to-right dependency visualization with D3.js
- **🎯 Smart Depth Control**: Precisely control analysis depth (1-10 levels) with real-time adjustment
- **📁 Flexible Entry Points**: Choose any Python file as the starting point for analysis
- **🔧 Git-aware**: Automatically respects .gitignore patterns and excludes irrelevant files

### Advanced Capabilities
- **🌳 Hierarchical Layout**: Structured left-to-right visualization showing clear dependency flow
- **🎛️ Real-time Controls**: Adjust depth, zoom, pan, and toggle labels without re-analysis
- **📊 Comprehensive Analysis**: Handles relative imports, absolute imports, and complex package structures
- **⚡ Performance Optimized**: Efficient analysis with configurable depth limits
- **🎨 Visual Clarity**: Color-coded nodes with clear entry point highlighting

## 📋 Requirements

- **Python 3.x**: Required for dependency analysis (extension auto-detects `python3` or `python`)
- **VS Code 1.96.0+**: Latest VS Code version for optimal compatibility

## 🎯 Usage

### Quick Start
1. **Open** a Python project in VS Code
2. **Run Command**: Use Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and select:
   - `Show Code Dependency Graph` - Interactive entry point selection
   - `Analyze Dependencies for Current File` - Analyze the currently open file

3. **Select Entry Point**: Choose your starting file through:
   - Current file in editor
   - File browser dialog
   - Manual path entry

4. **Explore Graph**: The extension opens with default depth 5 - perfect for most projects

### Graph Interaction
- **🖱️ Drag**: Reposition nodes vertically (horizontal positions maintain hierarchy)
- **🔍 Zoom**: Mouse wheel or pinch to zoom in/out
- **👆 Hover**: See full file paths and details
- **🎛️ Controls**: Use built-in controls for:
  - Reset zoom and center graph
  - Toggle node labels
  - **Real-time depth adjustment** (1-10 levels)

## 🎨 Graph Features

### Visual Elements
- **🎯 Entry Point**: Red border with larger size for easy identification
- **🟦 Python Files**: Blue nodes representing Python modules
- **➡️ Dependencies**: Directional arrows showing import relationships
- **📐 Hierarchical Layout**: Left-to-right structure showing dependency levels

### Layout Design
- **Level 0**: Entry point (leftmost)
- **Level 1**: Direct dependencies
- **Level 2+**: Nested dependencies flowing right
- **Clean Spacing**: 200px between levels, 60px between nodes

## ⚙️ Technical Details

### Python Analysis Engine
The extension leverages a sophisticated Python script (`find_unused_files.py`) that provides:

- **🔬 AST Parsing**: Advanced Abstract Syntax Tree analysis for 100% accurate import detection
- **📦 Package Handling**: Proper resolution of `__init__.py` files and package imports
- **🔗 Relative Imports**: Complete support for `.` and `..` relative import patterns
- **🌍 Absolute Imports**: Full project-wide import resolution
- **⛔ Gitignore Respect**: Automatic exclusion of ignored files and directories
- **🚀 Performance**: Optimized breadth-first traversal with depth limiting

### Supported Import Patterns
```python
# Standard imports
import os
import sys

# From imports
from pathlib import Path
from typing import List, Dict

# Relative imports
from . import sibling_module
from .submodule import function
from .. import parent_module
from ..utils import helper

# Package imports with __init__.py resolution
from mypackage import module  # Resolves to mypackage/__init__.py or mypackage/module.py
```

## 🔧 Configuration

### Depth Levels Explained
- **Depth 1**: Entry point + direct imports only
- **Depth 2**: Entry point + direct imports + their imports
- **Depth 3-5**: Recommended for most projects (good balance of detail vs. clarity)
- **Depth 6-10**: Large projects or comprehensive analysis

### Default Settings
- **Initial Depth**: 5 levels (optimal for most projects)
- **Max Depth Limit**: 10 levels (prevents performance issues)
- **Layout**: Hierarchical left-to-right
- **Entry Point Detection**: Auto-detects main files (`main.py`, `app.py`, etc.)

## 🚨 Troubleshooting

### Common Issues

**❌ "Python not found" error**
- Ensure Python 3 is installed and in your system PATH
- Extension tries both `python3` and `python` commands automatically
- Test with: `python3 --version` or `python --version` in terminal

**❌ Empty or minimal graph**
- Verify your entry point file exists and has imports
- Check if files are in .gitignore (they won't appear)
- Standard library imports (os, sys, etc.) are excluded by design
- Try increasing depth level if dependencies seem missing

**❌ Graph layout issues**
- Use "Center Graph" button to auto-fit the view
- Try "Reset Zoom" to return to default view
- Ensure window is large enough for proper layout

**❌ Performance issues**
- Reduce depth level for large projects
- Check .gitignore to exclude unnecessary directories
- Close other resource-intensive VS Code extensions

## 🏗️ Development

### Building from Source
```bash
git clone https://github.com/artinmajdi/Project-Template-Manager.git
cd extensions/code-dependency-visualizer
npm install
npm run compile
npx vsce package
```

### Architecture
- **Frontend**: TypeScript + VS Code API
- **Analysis Engine**: Python 3 with AST parsing
- **Visualization**: D3.js with custom hierarchical layout
- **Communication**: JSON-based IPC between TypeScript and Python

## 📝 Version History

### 🎉 v1.1.0 (Latest)
- **✅ Fixed depth filtering**: Level parameter now correctly limits dependency analysis depth
- **🎨 Improved graph layout**: Hierarchical left-to-right layout for superior readability
- **⚡ Streamlined UX**: Single-click start with default depth 5, adjustable in-graph
- **📐 Better positioning**: Structured node placement with clean, straight connection lines
- **🔧 Enhanced controls**: Real-time depth adjustment without re-analysis

### 🚀 v1.0.0
- **🔄 Complete rewrite**: Python-based dependency analysis for maximum accuracy
- **📈 Improved accuracy**: Significantly better Python import resolution
- **📦 Package support**: Enhanced handling of relative imports and package structures
- **🎮 Interactive controls**: Advanced graph visualization with zoom, pan, drag

### 🌱 v0.1.0
- **🎬 Initial release**: Basic dependency visualization
- **🔍 Multi-language**: TypeScript-based analysis (legacy)
- **📊 Force-directed**: Original force simulation layout (legacy)

## 📄 License

ISC License - See LICENSE file for details.

## 🤝 Contributing

Contributions welcome! Please feel free to submit pull requests or open issues on [GitHub](https://github.com/artinmajdi/Project-Template-Manager).

---

**💡 Pro Tip**: Start with depth 3-5 for most projects, then adjust based on your needs. The hierarchical layout makes it easy to trace dependency chains from left to right!
