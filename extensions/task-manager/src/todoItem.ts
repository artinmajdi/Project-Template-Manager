import * as vscode from 'vscode';

export class TodoItem extends vscode.TreeItem {
    public readonly id: string;
    public readonly text: string;
    public readonly isCompleted: boolean;
    public readonly source: 'manual' | 'codebase';
    public readonly file?: string;
    public readonly line?: number;
    public readonly category?: string;

    constructor(
        id: string,
        text: string,
        isCompleted: boolean = false,
        source: 'manual' | 'codebase' = 'manual',
        file?: string,
        line?: number,
        category?: string
    ) {
        super(text, vscode.TreeItemCollapsibleState.None);

        this.id = id;
        this.text = text;
        this.isCompleted = isCompleted;
        this.source = source;
        this.file = file;
        this.line = line;
        this.category = category;

        // Set the label with strikethrough for completed items and category badge
        let displayText = text;
        if (category && source === 'codebase') {
            const categoryEmoji = this.getCategoryEmoji(category);
            displayText = `${categoryEmoji} ${text}`;
        }
        this.label = isCompleted ? `~~${displayText}~~` : displayText;

        // Set icon based on completion status and category
        this.iconPath = new vscode.ThemeIcon(
            isCompleted ? 'check' : this.getCategoryIcon(category, source)
        );

        // Set context value for menu commands
        this.contextValue = 'todoItem';

        // Add tooltip
        this.tooltip = this.createTooltip();

        // Add command to open file if it's from codebase
        if (source === 'codebase' && file && line !== undefined) {
            this.command = {
                command: 'vscode.open',
                title: 'Open File',
                arguments: [
                    vscode.Uri.file(file),
                    { selection: new vscode.Range(line, 0, line, 0) }
                ]
            };
        }
    }

    private getCategoryEmoji(category?: string): string {
        if (!category) return '';

        switch (category.toLowerCase()) {
            case 'bug': return '🐛';
            case 'feature': return '✨';
            case 'refactor': return '♻️';
            case 'documentation': return '📚';
            case 'testing': return '🧪';
            default: return '📝';
        }
    }

    private getCategoryIcon(category?: string, source?: string): string {
        if (source === 'manual') return 'circle-outline';
        if (!category) return 'circle-outline';

        switch (category.toLowerCase()) {
            case 'bug': return 'bug';
            case 'feature': return 'star';
            case 'refactor': return 'tools';
            case 'documentation': return 'book';
            case 'testing': return 'beaker';
            default: return 'circle-outline';
        }
    }

    private createTooltip(): string {
        let tooltip = this.text;

        if (this.category) {
            tooltip += `\n\nCategory: ${this.category.charAt(0).toUpperCase() + this.category.slice(1)}`;
        }

        if (this.source === 'codebase' && this.file) {
            const fileName = this.file.split('/').pop() || this.file;
            tooltip += `\n\nFound in: ${fileName}`;
            if (this.line !== undefined) {
                tooltip += `:${this.line + 1}`;
            }
        }

        if (this.isCompleted) {
            tooltip += '\n\nStatus: Completed ✓';
        }

        return tooltip;
    }
}
