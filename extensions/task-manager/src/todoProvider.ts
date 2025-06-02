import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { TodoItem } from './todoItem';

interface Todo {
    id: string;
    text: string;
    isCompleted: boolean;
    source: 'manual' | 'codebase';
    file?: string;
    line?: number;
    dateCreated: string;
}

export class TodoProvider implements vscode.TreeDataProvider<TodoItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<TodoItem | undefined | null | void> = new vscode.EventEmitter<TodoItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<TodoItem | undefined | null | void> = this._onDidChangeTreeData.event;

    private todos: Todo[] = [];
    private todoFilePath: string;

    constructor(private context: vscode.ExtensionContext) {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (workspaceFolder) {
            this.todoFilePath = path.join(workspaceFolder.uri.fsPath, '.todo');
        } else {
            this.todoFilePath = path.join(context.globalStorageUri.fsPath, 'todos.json');
        }
    }

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: TodoItem): vscode.TreeItem {
        return element;
    }

    getChildren(element?: TodoItem): Thenable<TodoItem[]> {
        if (!element) {
            // Group todos by completion status
            const incompleteTodos = this.todos
                .filter(todo => !todo.isCompleted)
                .map(todo => new TodoItem(
                    todo.id,
                    todo.text,
                    todo.isCompleted,
                    todo.source,
                    todo.file,
                    todo.line
                ));

            const completedTodos = this.todos
                .filter(todo => todo.isCompleted)
                .map(todo => new TodoItem(
                    todo.id,
                    todo.text,
                    todo.isCompleted,
                    todo.source,
                    todo.file,
                    todo.line
                ));

            return Promise.resolve([...incompleteTodos, ...completedTodos]);
        }
        return Promise.resolve([]);
    }

    addTodo(text: string): void {
        const todo: Todo = {
            id: this.generateId(),
            text: text.trim(),
            isCompleted: false,
            source: 'manual',
            dateCreated: new Date().toISOString()
        };

        this.todos.push(todo);
        this.saveTodos();
        this.refresh();
    }

    deleteTodo(id: string): void {
        this.todos = this.todos.filter(todo => todo.id !== id);
        this.saveTodos();
        this.refresh();
    }

    toggleComplete(id: string): void {
        const todo = this.todos.find(t => t.id === id);
        if (todo) {
            todo.isCompleted = !todo.isCompleted;
            this.saveTodos();
            this.refresh();
        }
    }

    async syncTodosFromCodebase(): Promise<void> {
        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (!workspaceFolder) {
            vscode.window.showErrorMessage('No workspace folder found');
            return;
        }

        // Remove existing codebase todos
        this.todos = this.todos.filter(todo => todo.source === 'manual');

        try {
            const todoRegex = /(?:\/\/|#|<!--|\/\*)\s*(?:TODO|To-?Do)\s*:?\s*(.+?)(?:\*\/|-->|$)/gi;
            const files = await vscode.workspace.findFiles('**/*', '**/node_modules/**');

            for (const file of files) {
                const document = await vscode.workspace.openTextDocument(file);
                const text = document.getText();
                const lines = text.split('\n');

                lines.forEach((line, lineIndex) => {
                    let match;
                    while ((match = todoRegex.exec(line)) !== null) {
                        const todoText = match[1].trim();
                        if (todoText) {
                            const todo: Todo = {
                                id: this.generateId(),
                                text: todoText,
                                isCompleted: false,
                                source: 'codebase',
                                file: file.fsPath,
                                line: lineIndex,
                                dateCreated: new Date().toISOString()
                            };
                            this.todos.push(todo);
                        }
                    }
                });
            }

            this.saveTodos();
            this.refresh();
        } catch (error) {
            vscode.window.showErrorMessage(`Error syncing todos: ${error}`);
        }
    }

    loadTodos(): void {
        try {
            if (fs.existsSync(this.todoFilePath)) {
                const data = fs.readFileSync(this.todoFilePath, 'utf8');
                this.todos = JSON.parse(data);
                this.refresh();
            }
        } catch (error) {
            console.error('Error loading todos:', error);
            this.todos = [];
        }
    }

    private saveTodos(): void {
        try {
            // Ensure directory exists
            const dir = path.dirname(this.todoFilePath);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }

            fs.writeFileSync(this.todoFilePath, JSON.stringify(this.todos, null, 2));
        } catch (error) {
            console.error('Error saving todos:', error);
            vscode.window.showErrorMessage(`Error saving todos: ${error}`);
        }
    }

    private generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }
}
