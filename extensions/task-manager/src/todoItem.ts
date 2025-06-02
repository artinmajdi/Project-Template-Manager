import * as vscode from 'vscode';

export class TodoItem extends vscode.TreeItem {
    public readonly id: string;
    public readonly text: string;
    public readonly isCompleted: boolean;
    public readonly source: 'manual' | 'codebase';
    public readonly file?: string;
    public readonly line?: number;

    constructor(
        id: string,
        text: string,
        isCompleted: boolean = false,
        source: 'manual' | 'codebase' = 'manual',
        file?: string,
        line?: number
    ) {
        super(text, vscode.TreeItemCollapsibleState.None);

        this.id = id;
        this.text = text;
        this.isCompleted = isCompleted;
        this.source = source;
        this.file = file;
        this.line = line;

        // Set the label with strikethrough for completed items
        this.label = isCompleted ? `~~${text}~~` : text;

        // Set icon based on completion status
        this.iconPath = new vscode.ThemeIcon(
            isCompleted ? 'check' : 'circle-outline'
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

    private createTooltip(): string {
        let tooltip = this.text;

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
