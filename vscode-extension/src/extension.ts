// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { TemplateExplorerProvider, TemplateManager, TemplateTreeItem } from './templateExplorer';

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

	// Initialize template manager
	const templateManager = new TemplateManager(context);

	// Set up template explorer
	const workspaceRoot = vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders.length > 0
		? vscode.workspace.workspaceFolders[0].uri.fsPath
		: '';
	const templateExplorerProvider = new TemplateExplorerProvider(workspaceRoot, context);

	// Register the TreeDataProvider for the sidebar view
	vscode.window.registerTreeDataProvider('projectTemplateExplorer', templateExplorerProvider);

	// Install default template if available
	const defaultTemplatePath = path.join(context.extensionPath, 'template_example');
	if (fs.existsSync(defaultTemplatePath)) {
		templateManager.installDefaultTemplate(defaultTemplatePath).then(() => {
			templateExplorerProvider.refresh();
		});
	}

	const excludeItems = ['.git', '.vscode', 'node_modules', 'out', '.DS_Store', '.vscodeignore', '.gitignore', 'package.json', 'package-lock.json', 'tsconfig.json', 'eslint.config.mjs', '.vscode-test.mjs', 'CHANGELOG.md', 'vsc-extension-quickstart.md']; // Items to exclude when copying

	// Command: Create Full Project
	const createFullProjectCommand = vscode.commands.registerCommand('project-template-manager.createFullProject', async (node?: TemplateTreeItem) => {
		let selectedTemplate: string | undefined;

		// If command was triggered from the tree view
		if (node && node.contextValue === 'template') {
			selectedTemplate = node.templatePath;
		} else {
			// Show a quick pick to select a template
			const templatesDir = path.join(context.globalStorageUri.fsPath, 'templates');
			if (!fs.existsSync(templatesDir)) {
				vscode.window.showErrorMessage('No templates available. Please add a template first.');
				return;
			}

			const templates = fs.readdirSync(templatesDir, { withFileTypes: true })
				.filter(dirent => dirent.isDirectory())
				.map(dirent => ({
					label: dirent.name,
					description: 'Template',
					path: path.join(templatesDir, dirent.name)
				}));

			if (templates.length === 0) {
				vscode.window.showErrorMessage('No templates available. Please add a template first.');
				return;
			}

			const selectedOption = await vscode.window.showQuickPick(templates, {
				placeHolder: 'Select a template to use',
			});

			if (!selectedOption) {
				return; // User cancelled
			}

			selectedTemplate = selectedOption.path;
		}

		if (!selectedTemplate) {
			return;
		}

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
					await copyFolderRecursive(selectedTemplate!, targetDir, []);
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
	const addTemplateItemsCommand = vscode.commands.registerCommand('project-template-manager.addTemplateItems', async (node?: TemplateTreeItem) => {
		const workspaceFolders = vscode.workspace.workspaceFolders;
		if (!workspaceFolders || workspaceFolders.length === 0) {
			vscode.window.showErrorMessage('Cannot add template items: Please open a workspace folder first.');
			return;
		}
		// For simplicity, using the first workspace folder if multiple exist
		const targetWorkspaceDir = workspaceFolders[0].uri.fsPath;

		let selectedTemplate: string | undefined;

		// If command was triggered from the tree view
		if (node && node.contextValue === 'template') {
			selectedTemplate = node.templatePath;
		} else {
			// Show a quick pick to select a template
			const templatesDir = path.join(context.globalStorageUri.fsPath, 'templates');
			if (!fs.existsSync(templatesDir)) {
				vscode.window.showErrorMessage('No templates available. Please add a template first.');
				return;
			}

			const templates = fs.readdirSync(templatesDir, { withFileTypes: true })
				.filter(dirent => dirent.isDirectory())
				.map(dirent => ({
					label: dirent.name,
					description: 'Template',
					path: path.join(templatesDir, dirent.name)
				}));

			if (templates.length === 0) {
				vscode.window.showErrorMessage('No templates available. Please add a template first.');
				return;
			}

			const selectedOption = await vscode.window.showQuickPick(templates, {
				placeHolder: 'Select a template to use',
			});

			if (!selectedOption) {
				return; // User cancelled
			}

			selectedTemplate = selectedOption.path;
		}

		if (!selectedTemplate) {
			return;
		}

		try {
			const templateEntries = fs.readdirSync(selectedTemplate, { withFileTypes: true })
				.map(entry => ({
					label: entry.name,
					description: entry.isDirectory() ? 'Folder' : 'File',
					picked: false, // Default state
					isDirectory: entry.isDirectory(),
					sourcePath: path.join(selectedTemplate!, entry.name)
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

	// Command: Refresh Templates
	const refreshTemplatesCommand = vscode.commands.registerCommand('project-template-manager.refreshTemplates', () => {
		templateExplorerProvider.refresh();
	});

	// Command: Add Template
	const addTemplateCommand = vscode.commands.registerCommand('project-template-manager.addTemplate', async () => {
		const options: vscode.OpenDialogOptions = {
			canSelectMany: false,
			openLabel: 'Select Folder to Use as Template',
			canSelectFiles: false,
			canSelectFolders: true,
		};

		const folderUri = await vscode.window.showOpenDialog(options);
		if (folderUri && folderUri.length > 0) {
			const sourcePath = folderUri[0].fsPath;

			// Ask for template name
			const defaultName = path.basename(sourcePath);
			const templateName = await vscode.window.showInputBox({
				prompt: 'Enter a name for the template',
				value: defaultName
			});

			if (!templateName) {
				vscode.window.showInformationMessage('Template creation cancelled.');
				return;
			}

			try {
				vscode.window.withProgress({
					location: vscode.ProgressLocation.Notification,
					title: `Adding template "${templateName}"...`,
					cancellable: false
				}, async (progress) => {
					const result = await templateManager.addTemplate(sourcePath, templateName);
					if (result) {
						templateExplorerProvider.refresh();
						vscode.window.showInformationMessage(`Template "${templateName}" added successfully.`);
					} else {
						vscode.window.showErrorMessage(`Failed to add template "${templateName}".`);
					}
				});
			} catch (error: any) {
				console.error('Error adding template:', error);
				vscode.window.showErrorMessage(`Error adding template: ${error.message}`);
			}
		}
	});

	// Command: Delete Template
	const deleteTemplateCommand = vscode.commands.registerCommand('project-template-manager.deleteTemplate', async (node?: TemplateTreeItem) => {
		if (!node || node.contextValue !== 'template') {
			vscode.window.showErrorMessage('Please select a template to delete from the template explorer.');
			return;
		}

		const templateName = node.label;

		const confirmation = await vscode.window.showWarningMessage(
			`Are you sure you want to delete the template "${templateName}"?`,
			{ modal: true },
			'Delete'
		);

		if (confirmation === 'Delete') {
			try {
				const success = templateManager.deleteTemplate(templateName);
				if (success) {
					templateExplorerProvider.refresh();
					vscode.window.showInformationMessage(`Template "${templateName}" deleted successfully.`);
				} else {
					vscode.window.showErrorMessage(`Failed to delete template "${templateName}".`);
				}
			} catch (error: any) {
				console.error('Error deleting template:', error);
				vscode.window.showErrorMessage(`Error deleting template: ${error.message}`);
			}
		}
	});

	context.subscriptions.push(
		createFullProjectCommand,
		addTemplateItemsCommand,
		refreshTemplatesCommand,
		addTemplateCommand,
		deleteTemplateCommand
	);

	console.log('Extension "project-template-manager" is now active!');
}

// This method is called when your extension is deactivated
export function deactivate() {
	console.log('Extension "project-template-manager" is now deactivated.');
}
