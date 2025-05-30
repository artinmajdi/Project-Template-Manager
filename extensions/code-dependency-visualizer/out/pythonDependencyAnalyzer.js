"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.PythonDependencyAnalyzer = void 0;
const child_process_1 = require("child_process");
const path = __importStar(require("path"));
class PythonDependencyAnalyzer {
    constructor(extensionPath) {
        this.extensionPath = extensionPath;
    }
    async findPythonCommand() {
        const commands = ['python3', 'python'];
        for (const cmd of commands) {
            try {
                await new Promise((resolve, reject) => {
                    const process = (0, child_process_1.spawn)(cmd, ['--version'], { stdio: 'pipe' });
                    process.on('close', (code) => {
                        if (code === 0) {
                            resolve(cmd);
                        }
                        else {
                            reject();
                        }
                    });
                    process.on('error', () => reject());
                });
                return cmd;
            }
            catch {
                continue;
            }
        }
        throw new Error('Python not found. Please install Python 3 and ensure it\'s in your PATH.');
    }
    async analyzeDependencies(entryPoint, workspaceRoot, maxDepth = 10) {
        try {
            const pythonCmd = await this.findPythonCommand();
            return new Promise((resolve, reject) => {
                const pythonScript = path.join(this.extensionPath, 'find_unused_files.py');
                const relativePath = path.relative(workspaceRoot, entryPoint);
                console.log(`Running Python analyzer: ${pythonCmd} "${pythonScript}" --json-output --root "${workspaceRoot}" --max-depth ${maxDepth} "${relativePath}"`);
                const process = (0, child_process_1.spawn)(pythonCmd, [
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
                    }
                    catch (error) {
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
        }
        catch (error) {
            throw error;
        }
    }
}
exports.PythonDependencyAnalyzer = PythonDependencyAnalyzer;
//# sourceMappingURL=pythonDependencyAnalyzer.js.map