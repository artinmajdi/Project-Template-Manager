# Alternative Icon Configuration

If the extension icon is not showing up properly, you can try using an SVG icon instead of the codicon.

## Option 1: Using SVG Icon (Recommended)

Replace the icon line in package.json:

```json
"icon": "$(list-ordered)"
```

With:

```json
"icon": "resources/todo-icon.svg"
```

## Option 2: Using Different Codicons

Try these alternative codicons:
- `$(checklist)` - Checklist icon
- `$(list-unordered)` - Unordered list icon
- `$(tasklist)` - Task list icon
- `$(check)` - Check icon
- `$(circle-outline)` - Circle outline icon

## Option 3: Using Theme Icons

```json
"icon": {
  "light": "resources/todo-icon.svg",
  "dark": "resources/todo-icon.svg"
}
```

## Full Example

Here's the updated viewsContainers section:

```json
"viewsContainers": {
  "activitybar": [
    {
      "id": "todoManager",
      "title": "Todo Manager",
      "icon": "resources/todo-icon.svg"
    }
  ]
}
```

After making changes:
1. Run `npm run compile`
2. Package with `vsce package`
3. Reinstall the extension
4. Reload VS Code
