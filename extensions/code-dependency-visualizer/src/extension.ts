import * as vscode from 'vscode';
import { PythonDependencyAnalyzer } from './pythonDependencyAnalyzer';
import { GraphWebviewProvider } from './graphWebviewProvider';

export function activate(context: vscode.ExtensionContext) {
    console.log('Code Dependency Visualizer is now active!');

    const analyzer = new PythonDependencyAnalyzer(context.extensionPath);
    const webviewProvider = new GraphWebviewProvider(context.extensionUri);

    context.subscriptions.push(
        vscode.commands.registerCommand('codeDependencyVisualizer.showGraph', async () => {
            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders) {
                vscode.window.showErrorMessage('No workspace folder open');
                return;
            }

            const workspaceRoot = workspaceFolders[0].uri.fsPath;

            vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: "Analyzing dependencies...",
                cancellable: false
            }, async (progress) => {
                progress.report({ increment: 0 });

                const entryPoint = await selectEntryPoint(workspaceRoot);
                if (!entryPoint) {
                    return;
                }

                const maxDepth = 5; // Default depth, user can change it in the webview

                progress.report({ increment: 30, message: "Parsing files..." });
                const dependencies = await analyzer.analyzeDependencies(entryPoint, workspaceRoot, maxDepth);

                progress.report({ increment: 60, message: "Building graph..." });
                const panel = vscode.window.createWebviewPanel(
                    'dependencyGraph',
                    'Code Dependency Graph',
                    vscode.ViewColumn.One,
                    {
                        enableScripts: true,
                        retainContextWhenHidden: true
                    }
                );

                panel.webview.html = webviewProvider.getHtmlForWebview(panel.webview, dependencies);

                // Handle messages from the webview
                panel.webview.onDidReceiveMessage(
                    async message => {
                        switch (message.command) {
                            case 'changeDepth':
                                vscode.window.withProgress({
                                    location: vscode.ProgressLocation.Notification,
                                    title: `Re-analyzing with depth ${message.depth}...`,
                                    cancellable: false
                                }, async (progress) => {
                                    progress.report({ increment: 50 });
                                    const newDependencies = await analyzer.analyzeDependencies(entryPoint, workspaceRoot, message.depth);
                                    panel.webview.html = webviewProvider.getHtmlForWebview(panel.webview, newDependencies);
                                    progress.report({ increment: 100 });
                                });
                                break;
                        }
                    },
                    undefined,
                    context.subscriptions
                );

                progress.report({ increment: 100 });
            });
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('codeDependencyVisualizer.analyzeFile', async () => {
            const activeEditor = vscode.window.activeTextEditor;
            if (!activeEditor) {
                vscode.window.showErrorMessage('No active file');
                return;
            }

            const workspaceFolders = vscode.workspace.workspaceFolders;
            if (!workspaceFolders) {
                vscode.window.showErrorMessage('No workspace folder open');
                return;
            }

            const workspaceRoot = workspaceFolders[0].uri.fsPath;
            const currentFile = activeEditor.document.uri.fsPath;

            vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: "Analyzing dependencies for current file...",
                cancellable: false
            }, async (progress) => {
                progress.report({ increment: 20 });

                const maxDepth = 5; // Default depth, user can change it in the webview

                progress.report({ increment: 30 });

                const dependencies = await analyzer.analyzeDependencies(currentFile, workspaceRoot, maxDepth);

                progress.report({ increment: 60 });
                const panel = vscode.window.createWebviewPanel(
                    'dependencyGraph',
                    `Dependencies: ${vscode.workspace.asRelativePath(currentFile)}`,
                    vscode.ViewColumn.One,
                    {
                        enableScripts: true,
                        retainContextWhenHidden: true
                    }
                );

                panel.webview.html = webviewProvider.getHtmlForWebview(panel.webview, dependencies);

                // Handle messages from the webview
                panel.webview.onDidReceiveMessage(
                    async message => {
                        switch (message.command) {
                            case 'changeDepth':
                                vscode.window.withProgress({
                                    location: vscode.ProgressLocation.Notification,
                                    title: `Re-analyzing with depth ${message.depth}...`,
                                    cancellable: false
                                }, async (progress) => {
                                    progress.report({ increment: 50 });
                                    const newDependencies = await analyzer.analyzeDependencies(currentFile, workspaceRoot, message.depth);
                                    panel.webview.html = webviewProvider.getHtmlForWebview(panel.webview, newDependencies);
                                    progress.report({ increment: 100 });
                                });
                                break;
                        }
                    },
                    undefined,
                    context.subscriptions
                );

                progress.report({ increment: 100 });
            });
        })
    );
}

async function selectEntryPoint(workspaceRoot: string): Promise<string | undefined> {
    const options: vscode.QuickPickItem[] = [
        { label: 'Select current file', description: 'Use the currently open file as entry point' },
        { label: 'Browse for file', description: 'Browse and select a file' },
        { label: 'Enter path manually', description: 'Type the path to the entry point' }
    ];

    const selection = await vscode.window.showQuickPick(options, {
        placeHolder: 'How would you like to select the entry point?'
    });

    if (!selection) {
        return undefined;
    }

    switch (selection.label) {
        case 'Select current file':
            const activeEditor = vscode.window.activeTextEditor;
            if (activeEditor) {
                return activeEditor.document.uri.fsPath;
            } else {
                vscode.window.showErrorMessage('No file currently open');
                return undefined;
            }

        case 'Browse for file':
            const fileUri = await vscode.window.showOpenDialog({
                canSelectFiles: true,
                canSelectFolders: false,
                canSelectMany: false,
                openLabel: 'Select Entry Point',
                filters: {
                    'Code files': ['py', 'js', 'ts', 'jsx', 'tsx'],
                    'All files': ['*']
                }
            });
            return fileUri?.[0]?.fsPath;

        case 'Enter path manually':
            const path = await vscode.window.showInputBox({
                prompt: 'Enter the path to the entry point file',
                placeHolder: 'src/main.py'
            });
            if (path) {
                const fullPath = vscode.Uri.joinPath(vscode.Uri.file(workspaceRoot), path).fsPath;
                return fullPath;
            }
            return undefined;

        default:
            return undefined;
    }
}

async function selectDepthLevel(): Promise<number | undefined> {
    const input = await vscode.window.showInputBox({
        prompt: 'Enter the maximum depth level for dependency analysis',
        placeHolder: 'Enter a number (e.g., 3 for 3 levels deep)',
        value: '3',
        validateInput: (value) => {
            const num = parseInt(value);
            if (isNaN(num) || num < 1) {
                return 'Please enter a valid number greater than 0';
            }
            if (num > 10) {
                return 'Maximum depth is limited to 10 to prevent performance issues';
            }
            return null;
        }
    });

    if (input === undefined) {
        return undefined;
    }

    return parseInt(input);
}

export function deactivate() {}
