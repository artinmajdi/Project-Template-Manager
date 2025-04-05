// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

// Helper function to recursively copy a directory
async function copyFolderRecursive(source: string, target: string, exclude: string[] = []): Promise<void> {
	if (!fs.existsSync(target)) {
		fs.mkdirSync(target, { recursive: true });
	}

	const entries = fs.readdirSync(source, { withFileTypes: true });

	for (const entry of entries) {
		if (exclude.includes(entry.name)) {
			continue;
		}
		const sourcePath = path.join(source, entry.name);
		const targetPath = path.join(target, entry.name);

		if (entry.isDirectory()) {
			await copyFolderRecursive(sourcePath, targetPath, exclude);
		} else {
			fs.copyFileSync(sourcePath, targetPath);
		}
	}
}

// Helper function to copy a single file
function copyFile(source: string, targetDir: string, fileName: string): void {
	const targetPath = path.join(targetDir, fileName);
	if (!fs.existsSync(targetDir)) {
		fs.mkdirSync(targetDir, { recursive: true });
	}
	fs.copyFileSync(source, targetPath);
}

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Extension "project-template-manager" is activating.');

	const templateSourceDir = context.extensionPath; // The root of the extension IS the template
	const excludeItems = ['.git', '.vscode', 'node_modules', 'out', '.DS_Store', '.vscodeignore', '.gitignore', 'package.json', 'package-lock.json', 'tsconfig.json', 'eslint.config.mjs', '.vscode-test.mjs', 'CHANGELOG.md', 'vsc-extension-quickstart.md', 'README.md', 'src']; // Items to exclude when copying

	// Command: Create Full Project
	const createFullProjectCommand = vscode.commands.registerCommand('project-template-manager.createFullProject', async () => {
		const options: vscode.OpenDialogOptions = {
			canSelectMany: false,
			openLabel: 'Select Folder to Create Project In',
			canSelectFiles: false,
			canSelectFolders: true,
		};

		const folderUri = await vscode.window.showOpenDialog(options);
		if (folderUri && folderUri.length > 0) {
			const targetBasePath = folderUri[0].fsPath;
			// Optional: Ask for a project name or create a subfolder
			const projectName = await vscode.window.showInputBox({ prompt: 'Enter a name for the new project folder' });
			if (!projectName) {
				vscode.window.showWarningMessage('Project creation cancelled: No project name provided.');
				return; // User cancelled
			}
			const targetDir = path.join(targetBasePath, projectName);

			if (fs.existsSync(targetDir)) {
				vscode.window.showErrorMessage(`Folder "${projectName}" already exists in the selected location.`);
				return;
			}

			try {
				vscode.window.withProgress({
					location: vscode.ProgressLocation.Notification,
					title: `Creating project "${projectName}"...`,
					cancellable: false
				}, async (progress) => {
					progress.report({ increment: 0, message: 'Copying template files...' });
					await copyFolderRecursive(templateSourceDir, targetDir, excludeItems);
					progress.report({ increment: 100, message: 'Project created successfully.' });
					vscode.window.showInformationMessage(`Project "${projectName}" created successfully at ${targetDir}`);
					// Optional: Open the newly created folder
					const uri = vscode.Uri.file(targetDir);
					vscode.commands.executeCommand('vscode.openFolder', uri);
				});
			} catch (error: any) {
				console.error('Error creating full project:', error);
				vscode.window.showErrorMessage(`Error creating project: ${error.message}`);
			}
		} else {
			vscode.window.showInformationMessage('Project creation cancelled: No folder selected.');
		}
	});

	// Command: Add Template Items
	const addTemplateItemsCommand = vscode.commands.registerCommand('project-template-manager.addTemplateItems', async () => {
		const workspaceFolders = vscode.workspace.workspaceFolders;
		if (!workspaceFolders || workspaceFolders.length === 0) {
			vscode.window.showErrorMessage('Cannot add template items: Please open a workspace folder first.');
			return;
		}
		// For simplicity, using the first workspace folder if multiple exist
		const targetWorkspaceDir = workspaceFolders[0].uri.fsPath;

		try {
			const templateEntries = fs.readdirSync(templateSourceDir, { withFileTypes: true })
				.filter(entry => !excludeItems.includes(entry.name))
				.map(entry => ({
					label: entry.name,
					description: entry.isDirectory() ? 'Folder' : 'File',
					picked: false, // Default state
					isDirectory: entry.isDirectory(),
					sourcePath: path.join(templateSourceDir, entry.name)
				}));

			if (templateEntries.length === 0) {
				vscode.window.showInformationMessage('No template items available to add.');
				return;
			}

			const selectedItems = await vscode.window.showQuickPick(templateEntries, {
				canPickMany: true,
				placeHolder: 'Select files/folders from the template to add to your workspace',
			});

			if (selectedItems && selectedItems.length > 0) {
				vscode.window.withProgress({
					location: vscode.ProgressLocation.Notification,
					title: 'Adding template items...',
					cancellable: false
				}, async (progress) => {
					let copiedCount = 0;
					const total = selectedItems.length;

					for (const item of selectedItems) {
						progress.report({ increment: (1 / total) * 100, message: `Copying ${item.label}...` });
						const targetPath = path.join(targetWorkspaceDir, item.label);
						try {
							if (fs.existsSync(targetPath)) {
								const overwrite = await vscode.window.showWarningMessage(
									`"${item.label}" already exists in your workspace. Overwrite?`,
									{ modal: true }, // Make it modal so user must respond
									'Overwrite'
								);
								if (overwrite !== 'Overwrite') {
									vscode.window.showInformationMessage(`Skipped overwriting "${item.label}".`);
									continue; // Skip this item
								}
							}

							if (item.isDirectory) {
								await copyFolderRecursive(item.sourcePath, targetPath, []); // No excludes needed here for sub-copy
							} else {
								copyFile(item.sourcePath, targetWorkspaceDir, item.label);
							}
							copiedCount++;
						} catch (copyError: any) {
							console.error(`Error copying ${item.label}:`, copyError);
							vscode.window.showErrorMessage(`Failed to copy ${item.label}: ${copyError.message}`);
							// Decide if you want to stop or continue on error
						}
					}
					vscode.window.showInformationMessage(`${copiedCount} template item(s) added to workspace.`);
				});
			} else {
				vscode.window.showInformationMessage('No items selected.');
			}
		} catch (error: any) {
			console.error('Error reading template directory:', error);
			vscode.window.showErrorMessage(`Error accessing template items: ${error.message}`);
		}
	});

	context.subscriptions.push(createFullProjectCommand, addTemplateItemsCommand);

	console.log('Extension "project-template-manager" is now active!');
}

// This method is called when your extension is deactivated
export function deactivate() {
	console.log('Extension "project-template-manager" is now deactivated.');
}
