# Publishing Your Extension to VS Code Marketplace

This guide provides step-by-step instructions for publishing your Project Template Manager extension to the official VS Code Marketplace.

## Prerequisites

- Your completed VS Code extension
- A Microsoft account (for the Marketplace)
- Node.js installed on your system

## Step 1: Install vsce

The `vsce` tool (Visual Studio Code Extensions) is the command-line utility for managing VS Code extensions.

```bash
npm install -g @vscode/vsce
```

## Step 2: Create a Publisher

You need a publisher identity to publish extensions to the VS Code Marketplace.

1. Sign up or log in to [Azure DevOps](https://dev.azure.com)
2. Create a Personal Access Token (PAT):
   - Go to your user settings (top right) → Personal Access Tokens
   - Click "New Token"
   - Give it a name like "VS Code Extension Publishing"
   - Set the organization to "All accessible organizations" (very important!)
   - Set the expiration as desired (up to 1 year)
   - Select "Marketplace" scope and check "Manage" permission
   - Click "Create" and **copy the token** (you'll only see it once)

3. Create a publisher using vsce:

   ```bash
   vsce create-publisher YOUR_PUBLISHER_NAME
   ```

   When prompted, enter the Personal Access Token you created.

## Step 3: Prepare Your Extension

Ensure your `package.json` includes all required fields:

```json
{
  "name": "project-template-manager",
  "displayName": "Project Template Manager",
  "description": "...",
  "version": "1.0.0",
  "publisher": "YOUR_PUBLISHER_NAME",
  "engines": {
    "vscode": "^1.96.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/username/project_template"
  },
  "categories": ["Other"],
  "keywords": ["templates", "project", "scaffolding"],
  "icon": "resources/template-icon.png",
  ...
}
```

Important notes:

- Ensure you have a good `README.md` file - it will be displayed on the marketplace page
- Include a license file
- Add an icon (128x128px PNG) and reference it in package.json
- Use 10 or fewer tags/keywords to avoid publishing errors
- Ensure your repository URL is correct

## Step 4: Create a .vscodeignore File

Create a `.vscodeignore` file to exclude unnecessary files from your extension package:

```
.vscode/**
.vscode-test/**
.gitignore
vsc-extension-quickstart.md
**/tsconfig.json
**/.eslintrc.json
**/*.map
**/*.ts
node_modules/**
```

## Step 5: Package Your Extension

Test packaging your extension locally first:

```bash
cd vscode-extension
vsce package
```

This creates a `.vsix` file that you can install locally to test.

## Step 6: Publish Your Extension

If you've already logged in with your publisher:

```bash
vsce publish
```

Or to specify the version:

```bash
vsce publish minor  # increments the minor version
# or
vsce publish 1.0.0  # sets a specific version
```

If you haven't logged in yet:

```bash
vsce login YOUR_PUBLISHER_NAME
# Or publish with token directly
vsce publish -p <your-token>
```

## Step 7: Verify Your Extension

1. Wait a few minutes for processing
2. Visit the [VS Code Marketplace](https://marketplace.visualstudio.com/)
3. Search for your extension by name
4. You can also check your extensions at:

   ```
   https://marketplace.visualstudio.com/manage/publishers/YOUR_PUBLISHER_NAME
   ```

## Updating Your Extension

To update your extension:

1. Make your changes
2. Update the version in `package.json`
3. Run `vsce publish` again

Alternatively, use the auto-increment feature:

```bash
vsce publish patch  # 1.0.0 -> 1.0.1
vsce publish minor  # 1.0.0 -> 1.1.0
vsce publish major  # 1.0.0 -> 2.0.0
```

## Troubleshooting Common Issues

- **"403 Forbidden" or "401 Unauthorized"**: Make sure you selected "All accessible organizations" when creating your token and set the proper "Marketplace (Manage)" scope.
- **"Extension already exists"**: The extension name must be unique in the marketplace.
- **"Exceeded the number of allowed tags"**: Keep keywords under 10.
- **SVG Security Issues**: Due to security concerns, `vsce` will not publish extensions with user-provided SVG images. Use PNG for your icon.

## Support

For marketplace support, visit the [Manage Publishers & Extensions](https://marketplace.visualstudio.com/manage) page and click "Contact Microsoft"

## Additional Resources

- [VS Code Extension API Documentation](https://code.visualstudio.com/api)
- [Publishing Extensions Documentation](https://code.visualstudio.com/api/working-with-extensions/publishing-extension)
