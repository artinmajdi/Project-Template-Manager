import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { spawn } from 'child_process';
import { TodoItem } from './todoItem';

interface Todo {
    id: string;
    text: string;
    isCompleted: boolean;
    source: 'manual' | 'codebase';
    file?: string;
    line?: number;
    dateCreated: string;
    category?: string;
}

interface PythonTodoResult {
    workspace: string;
    generated_at: string;
    total_todos: number;
    todos: Array<{
        id: number;
        file: string;
        line: number;
        text: string;
        context: string;
        category: string;
        timestamp: string;
    }>;
}

export class TodoProvider implements vscode.TreeDataProvider<TodoItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<TodoItem | undefined | null | void> = new vscode.EventEmitter<TodoItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<TodoItem | undefined | null | void> = this._onDidChangeTreeData.event;

    private todos: Todo[] = [];
    private todoFilePath: string;

    constructor(private context: vscode.ExtensionContext) {
        // Ensure the global storage directory exists
        const globalStorageUri = context.globalStorageUri;
        fs.mkdirSync(globalStorageUri.fsPath, { recursive: true });

        const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
        if (workspaceFolder) {
            this.todoFilePath = path.join(workspaceFolder.uri.fsPath, '.todo');
        } else {
            this.todoFilePath = path.join(globalStorageUri.fsPath, 'todos.json');
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
                    todo.line,
                    todo.category
                ));

            const completedTodos = this.todos
                .filter(todo => todo.isCompleted)
                .map(todo => new TodoItem(
                    todo.id,
                    todo.text,
                    todo.isCompleted,
                    todo.source,
                    todo.file,
                    todo.line,
                    todo.category
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
            // Try to use the Python script first
            const pythonTodos = await this.runPythonScript(workspaceFolder.uri.fsPath);

            if (pythonTodos) {
                // Process Python script results
                pythonTodos.todos.forEach(todo => {
                    const newTodo: Todo = {
                        id: this.generateId(),
                        text: todo.text,
                        isCompleted: false,
                        source: 'codebase',
                        file: path.resolve(workspaceFolder.uri.fsPath, todo.file),
                        line: todo.line - 1, // Convert to 0-based index for VSCode
                        dateCreated: new Date().toISOString(),
                        category: todo.category
                    };
                    this.todos.push(newTodo);
                });

                this.saveTodos();
                this.refresh();

                vscode.window.showInformationMessage(
                    `Found ${pythonTodos.total_todos} TODOs using advanced detection (with gitignore support)`
                );
                return;
            }
        } catch (error) {
            console.warn('Python script failed, falling back to regex method:', error);
            vscode.window.showWarningMessage(
                'Advanced TODO detection failed, using basic method. Install Python and pathspec for better results.'
            );
        }

        // Fallback to original regex method
        await this.syncTodosWithRegex(workspaceFolder);
    }

    private async runPythonScript(workspacePath: string): Promise<PythonTodoResult | null> {
        return new Promise((resolve, reject) => {
            // Get the path to the Python script
            const extensionPath = this.context.extensionPath;
            const scriptPath = path.join(extensionPath, 'scripts', 'find_todos.py');

            // Check if script exists
            if (!fs.existsSync(scriptPath)) {
                reject(new Error('Python script not found'));
                return;
            }

            // Try different Python commands
            const pythonCommands = ['python3', 'python'];
            let commandIndex = 0;

            const tryNextCommand = () => {
                if (commandIndex >= pythonCommands.length) {
                    reject(new Error('No working Python interpreter found'));
                    return;
                }

                const pythonCmd = pythonCommands[commandIndex];
                const args = [scriptPath, workspacePath, '--extension-mode'];

                const process = spawn(pythonCmd, args, {
                    cwd: workspacePath,
                    stdio: ['pipe', 'pipe', 'pipe']
                });

                let stdout = '';
                let stderr = '';

                process.stdout.on('data', (data) => {
                    stdout += data.toString();
                });

                process.stderr.on('data', (data) => {
                    stderr += data.toString();
                });

                process.on('close', (code) => {
                    if (code === 0 && stdout.trim()) {
                        try {
                            const result = JSON.parse(stdout);
                            resolve(result);
                        } catch (parseError) {
                            console.error('Failed to parse JSON output:', parseError);
                            console.error('Raw output:', stdout);
                            commandIndex++;
                            tryNextCommand();
                        }
                    } else {
                        console.error(`Python command failed with code ${code}`);
                        console.error('stderr:', stderr);
                        commandIndex++;
                        tryNextCommand();
                    }
                });

                process.on('error', (error) => {
                    console.error(`Failed to start ${pythonCmd}:`, error);
                    commandIndex++;
                    tryNextCommand();
                });
            };

            tryNextCommand();
        });
    }

    private async syncTodosWithRegex(workspaceFolder: vscode.WorkspaceFolder): Promise<void> {
        try {
            const todoRegex = /(?:\/\/|#|<!--|\/\*)\s*(?:TODO|To-?Do)\s*:?\s*(.+?)(?:\*\/|-->|$)/gi;
            const files = await vscode.workspace.findFiles('**/*', '**/node_modules/**');

            for (const file of files) {
                const document = await vscode.workspace.openTextDocument(file);
                const text = document.getText();
                const lines = text.split('\n');

                lines.forEach((line, lineIndex) => {
                    let match;
                    const regex = new RegExp(todoRegex);
                    while ((match = regex.exec(line)) !== null) {
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
