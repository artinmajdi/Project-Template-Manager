// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import { TodoProvider } from './todoProvider';
import { TodoItem } from './todoItem';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Todo Manager extension is now active!');

	const todoProvider = new TodoProvider(context);

	    // Register the tree data provider
    vscode.window.registerTreeDataProvider('todoManagerView', todoProvider);

	// Register commands
	const refreshCommand = vscode.commands.registerCommand('todoManager.refresh', () => {
		todoProvider.refresh();
	});

	const syncCommand = vscode.commands.registerCommand('todoManager.sync', async () => {
		await todoProvider.syncTodosFromCodebase();
		vscode.window.showInformationMessage('Todos synced from codebase!');
	});

	const addTodoCommand = vscode.commands.registerCommand('todoManager.addTodo', async () => {
		const text = await vscode.window.showInputBox({
			prompt: 'Enter todo text',
			placeHolder: 'What needs to be done?'
		});

		if (text) {
			todoProvider.addTodo(text);
		}
	});

	const deleteTodoCommand = vscode.commands.registerCommand('todoManager.deleteTodo', (item: TodoItem) => {
		todoProvider.deleteTodo(item.id);
	});

	const toggleCompleteCommand = vscode.commands.registerCommand('todoManager.toggleComplete', (item: TodoItem) => {
		todoProvider.toggleComplete(item.id);
	});

	// Add all commands to subscriptions
	context.subscriptions.push(
		refreshCommand,
		syncCommand,
		addTodoCommand,
		deleteTodoCommand,
		toggleCompleteCommand
	);

	// Load todos when extension activates
	todoProvider.loadTodos();
}

// This method is called when your extension is deactivated
export function deactivate() {}
