# Todo Manager Extension Troubleshooting Guide

## Common Issues and Solutions

### 1. Extension Not Showing in Activity Bar

**Issue**: The Todo Manager icon doesn't appear in the VS Code activity bar (left sidebar).

**Solutions**:

- **Workspace Folder**: The original configuration required a workspace folder to be open. This has been fixed, but make sure you:
  - Have a folder open in VS Code when testing
  - Or use the updated `package.json` without the `when` condition

- **Extension Not Activated**: Check if the extension is activated:
  1. Open Command Palette (Cmd+Shift+P)
  2. Type "Developer: Show Running Extensions"
  3. Look for "Todo Manager" in the list

- **Reload VS Code**: After installing the extension:
  1. Open Command Palette (Cmd+Shift+P)
  2. Type "Developer: Reload Window"

### 2. Installation Issues

**To properly install the extension**:

1. **Build the extension**:

   ```bash
   cd "/Users/artinmajdi/Documents/GitHubs/Career/Vibe Coding/project_template_manager/extensions/task-manager"
   npm install
   npm run compile
   ```

2. **Package the extension**:

   ```bash
   # Install vsce if not already installed
   npm install -g @vscode/vsce

   # Package the extension
   vsce package
   ```

3. **Install the extension**:
   - Open VS Code
   - Open Command Palette (Cmd+Shift+P)
   - Type "Extensions: Install from VSIX..."
   - Select the generated `.vsix` file

### 3. Icon Not Displaying

The extension uses VS Code's built-in codicons. If the icon doesn't show:

- Try using a different icon format in `package.json`
- Use an SVG icon file instead

### 4. Debugging the Extension

To debug the extension:

1. Open the extension folder in VS Code
2. Press F5 to launch a new VS Code instance with the extension loaded
3. Check the Debug Console for any errors

### 5. Check Extension Logs

1. Open Command Palette (Cmd+Shift+P)
2. Type "Developer: Toggle Developer Tools"
3. Check the Console tab for any errors related to the extension

## Verification Steps

After making changes:

1. Compile: `npm run compile`
2. Package: `vsce package`
3. Uninstall old version from VS Code
4. Install new version
5. Reload VS Code window

## Additional Fixes Applied

1. Removed `when: "workspaceHasFolder"` condition from the view
2. Added directory creation for global storage to prevent errors
3. Improved error handling for missing workspace folders

## Testing the Extension

1. **Without Workspace**:
   - Open VS Code without any folder
   - The Todo Manager should still appear in the activity bar
   - Todos will be saved globally

2. **With Workspace**:
   - Open a folder in VS Code
   - The Todo Manager should appear
   - Todos will be saved in `.todo` file in the workspace

3. **Sync Feature**:
   - Add some TODO comments in your code
   - Click the sync button
   - Todos should be extracted from the codebase
