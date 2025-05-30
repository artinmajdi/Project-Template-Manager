import * as vscode from 'vscode';
import * as path from 'path';
import * as cp from 'child_process';
import * as fs from 'fs';

export function activate(context: vscode.ExtensionContext) {
    console.log('Congratulations, your extension "codedependency-visualizer" is now active!');

    let disposable = vscode.commands.registerCommand('codedependency-visualizer.visualizeDependencies', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showWarningMessage('No active editor. Please open a Python file to visualize its dependencies.');
            return;
        }

        const document = editor.document;
        if (document.languageId !== 'python') {
            vscode.window.showWarningMessage('Please open a Python file to visualize its dependencies.');
            return;
        }

        const entryPointPath = document.fileName;
        const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
        const projectRoot = workspaceFolder ? workspaceFolder.uri.fsPath : path.dirname(entryPointPath);

        vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Analyzing Dependencies",
            cancellable: false
        }, async (progress: vscode.Progress<{ message?: string; increment?: number }>) => {
            progress.report({ increment: 0, message: "Starting analysis..." });

            const pythonScriptPath = path.join(context.extensionPath, 'find_unused_files.py');

            // Ensure the python script is executable, or use python interpreter explicitly
            // For simplicity, let's assume python3 is in PATH and can execute the script.
            const command = `python3 "${pythonScriptPath}" --generate-json-graph "${entryPointPath}" --root "${projectRoot}"`;

            progress.report({ increment: 20, message: "Running Python script..." });

            cp.exec(command, { cwd: projectRoot }, (error, stdout, stderr) => {
                if (error) {
                    console.error(`exec error: ${error}`);
                    vscode.window.showErrorMessage(`Error executing Python script: ${error.message}.\nStderr: ${stderr}`);
                    progress.report({ increment: 100 });
                    return;
                }
                if (stderr) {
                    console.warn(`Python script stderr: ${stderr}`);
                    // Optionally show stderr as a warning if it's not empty but no error code
                    // vscode.window.showWarningMessage(`Python script warnings: ${stderr}`);
                }

                progress.report({ increment: 70, message: "Processing graph data..." });

                try {
                    const graphDataString = stdout.substring(stdout.indexOf('{')); // Attempt to find the start of the JSON
                    const graphData = JSON.parse(graphDataString);

                    const panel = vscode.window.createWebviewPanel(
                        'dependencyGraph',
                        `Dependencies: ${path.basename(entryPointPath)}`,
                        vscode.ViewColumn.One,
                        {
                            enableScripts: true,
                            localResourceRoots: [vscode.Uri.joinPath(context.extensionUri, 'media'), vscode.Uri.joinPath(context.extensionUri, 'node_modules')]
                        }
                    );

                    panel.webview.html = getWebviewContent(panel.webview, context.extensionUri, graphData);
                    progress.report({ increment: 100, message: "Graph displayed." });

                } catch (parseError) {
                    console.error(`JSON parse error: ${parseError}`);
                    console.error('Raw stdout from script:\n', stdout);
                    vscode.window.showErrorMessage(`Failed to parse dependency data from Python script. Output: ${stdout}`);
                    progress.report({ increment: 100 });
                }
            });
        });
    });

    context.subscriptions.push(disposable);
}

function getWebviewContent(webview: vscode.Webview, extensionUri: vscode.Uri, graphData: any): string {
    const visNetworkUri = webview.asWebviewUri(vscode.Uri.joinPath(extensionUri, 'node_modules', 'vis-network', 'standalone', 'umd', 'vis-network.min.js'));
    const nonce = getNonce();

    return `<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Code Dependency Graph</title>
        <script type="text/javascript" src="${visNetworkUri}"></script>
        <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; overflow: hidden; }
            #mynetwork {
                width: 100%;
                height: 100%;
                border: 1px solid lightgray;
            }
        </style>
    </head>
    <body>
        <div id="mynetwork"></div>
        <script nonce="${nonce}">
            const vscode = acquireVsCodeApi();
            const nodes = new vis.DataSet(${JSON.stringify(graphData.nodes)});
            const edges = new vis.DataSet(${JSON.stringify(graphData.edges)});
            const container = document.getElementById('mynetwork');
            const data = {
                nodes: nodes,
                edges: edges
            };
            const options = {
                layout: {
                    hierarchical: {
                        enabled: true,
                        direction: 'LR', // Left to Right
                        sortMethod: 'directed', // Sort by the direction of edges
                        levelSeparation: 250,
                        nodeSpacing: 150,
                        treeSpacing: 200
                    }
                },
                interaction: {
                    dragNodes: true,
                    dragView: true,
                    zoomView: true
                },
                physics: {
                    enabled: false // Disable physics for hierarchical layout, or tune if preferred
                },
                nodes: {
                    shape: 'box',
                    margin: 10,
                    font: {
                        size: 12,
                        face: 'monospace'
                    },
                    widthConstraint: { maximum: 200 }
                },
                edges: {
                    arrows: 'to',
                    smooth: {
                        type: 'cubicBezier',
                        forceDirection: 'horizontal',
                        roundness: 0.4
                    }
                }
            };
            const network = new vis.Network(container, data, options);

            // Highlight entry point
            if (graphData.entryPointId) {
                network.selectNodes([graphData.entryPointId], true);
                nodes.update([{id: graphData.entryPointId, color: { background: '#97C2FC', border: '#2B7CE9'}}]);
            }
        </script>
    </body>
    </html>`;
}

function getNonce() {
    let text = '';
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    for (let i = 0; i < 32; i++) {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}

export function deactivate() {}
