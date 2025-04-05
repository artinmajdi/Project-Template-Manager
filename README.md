# Project Template Manager - Development Guide

This document provides instructions for building, installing, and using the Project Template Manager extension.

## Building and Installing the Extension

### Prerequisites

- [Node.js](https://nodejs.org/) (v14.0.0 or later)
- [npm](https://www.npmjs.com/) (comes with Node.js)
- [VS Code](https://code.visualstudio.com/) or [Cursor](https://cursor.sh/) IDE

### Building the Extension

1. **Clone the repository**

   ```bash
   git clone https://github.com/artinmajdi/Project-Template-Manager.git
   cd Project-Template-Manager/vscode-extension
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Compile the extension**

   ```bash
   npm run compile
   ```

4. **Package the extension**

   ```bash
   # Install vsce if you don't have it
   npm install -g @vscode/vsce

   # Create the VSIX package
   vsce package
   ```

   This will generate a `project-template-manager-0.0.1.vsix` file.

### Installing the Extension

#### In VS Code

```bash
code --install-extension project-template-manager-0.0.1.vsix
```

#### In Cursor IDE

```bash
cursor --install-extension project-template-manager-0.0.1.vsix
```

## Using the Extension with Template Examples

### Adding the Template Example to Your Extension

The Project Template Manager uses the extension directory as the source for templates. To use the provided `pythonic_template` as your template:

1. **Option 1: Copy to Extension Directory**
   - Copy the contents of the `pythonic_template` directory to the extension's installation directory
   - This allows the template example to be used immediately

   > **Note**: Finding the extension directory varies by platform:
   > - Windows: `%USERPROFILE%\.vscode\extensions\artinmajdi.project-template-manager-0.0.1`
   > - macOS: `~/.vscode/extensions/artinmajdi.project-template-manager-0.0.1`
   > - Linux: `~/.vscode/extensions/artinmajdi.project-template-manager-0.0.1`
   >
   > For Cursor IDE, replace `.vscode` with `.cursor`

2. **Option 2: Create a Symbolic Link**
   - Create a symbolic link from the extension directory to your template example

   ```bash
   # On macOS/Linux
   ln -s /path/to/pythonic_template/* ~/.vscode/extensions/artinmajdi.project-template-manager-0.0.1/template

   # On Windows (Command Prompt as Administrator)
   mklink /D "%USERPROFILE%\.vscode\extensions\artinmajdi.project-template-manager-0.0.1\template" "path\to\pythonic_template"
   ```

### Using the Extension

After installation, you can use the extension with the following commands:

1. **Create a Full Project**
   - Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux) to open the Command Palette
   - Type "Project Template: Create Full Project" and select it
   - Choose a destination folder where you want to create the project
   - Enter a name for the new project folder
   - The extension will create a new project with the template structure

2. **Add Template Items to an Existing Project**
   - Open the folder/workspace where you want to add template items
   - Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux) to open the Command Palette
   - Type "Project Template: Add Files/Folders from Template" and select it
   - Select the files or folders from the template that you want to add to your project
   - The selected items will be copied to your workspace

## Making Changes to Templates

When you make changes to your template files:

1. If using Option 1 (direct copy), you'll need to copy the updated files to the extension directory again.
2. If using Option 2 (symbolic link), changes will be reflected automatically since you're working with the linked files.

## Troubleshooting

- If commands aren't showing up in the Command Palette, try reloading the window (`Cmd+Shift+P` → "Developer: Reload Window")
- Check the Output panel (`View` → `Output`) and select "Project Template Manager" from the dropdown to see debug logs

## Further Development

- To make changes to the extension itself, modify the files in the `src` directory
- After making changes, rebuild the extension following the steps in the "Building the Extension" section
- For significant changes, increment the version number in `package.json`
