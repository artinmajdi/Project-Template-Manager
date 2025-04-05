# Project Template Manager

A VS Code extension that allows you to create projects from template structures or add specific template files/folders to an existing project. This extension includes a sidebar view to manage templates and helps you reuse project structures.

## Features

This extension provides several ways to work with project templates:

1. **Template Explorer Sidebar**: View your current project structure and available templates.
2. **Create Full Project**: Creates a complete project structure from a template.
3. **Add Template Items**: Selectively adds specific files or folders from a template to your existing project.
4. **Manage Templates**: Add new templates, delete existing ones, and refresh the template view.

## Template Explorer

The Template Explorer sidebar provides:

- A view of your current project structure at the top
- A list of all available templates at the bottom
- Template management capabilities via context menus

![Template Explorer](resources/screenshot.png)

## How to Use

### Using the Template Explorer

1. Click on the Project Templates icon in the activity bar to open the Template Explorer.
2. The top section shows your current project structure (if a workspace is open).
3. The bottom section shows available templates that you can use.
4. Right-click on a template to:
   - Create a new project from the template
   - Add specific files/folders from the template
   - Delete the template

### Creating a New Project

1. Open the Template Explorer and right-click on a template, then select "Create Full Project from Template"
   - OR -
   Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac) to open the Command Palette.
2. Type "Create Full Project from Template" and select it.
3. Choose a location where you want to create your project.
4. Enter a name for your new project folder.
5. The extension will create a new project with all the template files and folders.

### Adding Template Items to an Existing Project

1. Open the folder/workspace where you want to add template items.
2. Open the Template Explorer and right-click on a template, then select "Add Files/Folders from Template"
   - OR -
   Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac) to open the Command Palette.
3. Type "Add Files/Folders from Template" and select it.
4. Select the files or folders from the template that you want to add.
5. The selected items will be copied to your current workspace.

### Managing Templates

#### Adding a Template
1. Click the "+" button in the Template Explorer title bar.
2. Select a folder to use as a template.
3. Enter a name for the template.

#### Deleting a Template
1. Right-click on a template in the Template Explorer.
2. Select "Delete Template".
3. Confirm the deletion.

## Included Template

The extension comes with a default "pythonic_template" that demonstrates a well-structured Python project with:

- Standardized project layout
- Configuration management
- Data processing utilities
- Documentation structure
- Test framework setup

Feel free to use this as a starting point for your own templates or delete it if not needed.

## Requirements

- Visual Studio Code 1.96.0 or higher

## Extension Settings

This extension doesn't add any VS Code settings yet.

## Release Notes

### 1.0.0

Initial release of Project Template Manager extension with:
- Template Explorer sidebar
- Template management (add, delete, refresh)
- Create Full Project command
- Add Template Items command
- Default template example

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0), which permits non-commercial use with attribution.

Any files, code, or project structures created or modified by this extension are the sole responsibility of the user. The author bears no responsibility for any issues, errors, or consequences arising from projects created or modified using this extension.

See the [LICENSE](LICENSE) file for details.

---

**Enjoy using Project Template Manager!**
