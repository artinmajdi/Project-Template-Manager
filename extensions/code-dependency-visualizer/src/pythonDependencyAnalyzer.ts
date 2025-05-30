import * as vscode from 'vscode';
import { spawn } from 'child_process';
import * as path from 'path';
import { DependencyGraph } from './dependencyAnalyzer';

export class PythonDependencyAnalyzer {
    private extensionPath: string;

    constructor(extensionPath: string) {
        this.extensionPath = extensionPath;
    }

    private async findPythonCommand(): Promise<string> {
        const commands = ['python3', 'python'];

        for (const cmd of commands) {
            try {
                await new Promise((resolve, reject) => {
                    const process = spawn(cmd, ['--version'], { stdio: 'pipe' });
                    process.on('close', (code) => {
                        if (code === 0) {
                            resolve(cmd);
                        } else {
                            reject();
                        }
                    });
                    process.on('error', () => reject());
                });
                return cmd;
            } catch {
                continue;
            }
        }

        throw new Error('Python not found. Please install Python 3 and ensure it\'s in your PATH.');
    }

    async analyzeDependencies(entryPoint: string, workspaceRoot: string, maxDepth: number = 10): Promise<DependencyGraph> {
        try {
            const pythonCmd = await this.findPythonCommand();

            return new Promise((resolve, reject) => {
                const pythonScript = path.join(this.extensionPath, 'find_unused_files.py');
                const relativePath = path.relative(workspaceRoot, entryPoint);

                console.log(`Running Python analyzer: ${pythonCmd} "${pythonScript}" --json-output --root "${workspaceRoot}" --max-depth ${maxDepth} "${relativePath}"`);

                const process = spawn(pythonCmd, [
                    pythonScript,
                    '--json-output',
                    '--root', workspaceRoot,
                    '--max-depth', maxDepth.toString(),
                    relativePath
                ], {
                    cwd: workspaceRoot,
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
                    if (code !== 0) {
                        console.error('Python script stderr:', stderr);
                        reject(new Error(`Python script failed with code ${code}: ${stderr}`));
                        return;
                    }

                    try {
                        const result = JSON.parse(stdout);
                        console.log('Python analysis result:', result);
                        resolve(result);
                    } catch (error) {
                        console.error('Failed to parse Python script output:', stdout);
                        console.error('Error:', error);
                        reject(new Error(`Failed to parse Python script output: ${error}`));
                    }
                });

                process.on('error', (error) => {
                    console.error('Failed to start Python script:', error);
                    reject(new Error(`Failed to start Python script: ${error}`));
                });
            });
        } catch (error) {
            throw error;
        }
    }
}
