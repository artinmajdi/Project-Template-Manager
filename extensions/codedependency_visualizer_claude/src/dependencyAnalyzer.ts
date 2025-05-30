import * as fs from 'fs';
import * as path from 'path';
import { promisify } from 'util';

const readFile = promisify(fs.readFile);
const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);

export interface DependencyNode {
    id: string;
    label: string;
    fullPath: string;
    type: 'python' | 'javascript' | 'typescript' | 'unknown';
}

export interface DependencyEdge {
    source: string;
    target: string;
}

export interface DependencyGraph {
    nodes: DependencyNode[];
    edges: DependencyEdge[];
    entryPoint: string;
}

export class DependencyAnalyzer {
    private processedFiles: Set<string> = new Set();
    private nodes: Map<string, DependencyNode> = new Map();
    private edges: DependencyEdge[] = [];
    private workspaceRoot: string = '';
    private gitignorePatterns: RegExp[] = [];

    async analyzeDependencies(entryPoint: string, workspaceRoot: string): Promise<DependencyGraph> {
        this.workspaceRoot = workspaceRoot;
        this.processedFiles.clear();
        this.nodes.clear();
        this.edges = [];
        
        // Load gitignore patterns
        await this.loadGitignorePatterns();
        
        // Start analysis from entry point
        await this.analyzeFile(entryPoint);
        
        return {
            nodes: Array.from(this.nodes.values()),
            edges: this.edges,
            entryPoint: path.relative(workspaceRoot, entryPoint)
        };
    }

    private async loadGitignorePatterns() {
        const defaultPatterns = [
            /^__pycache__\//,
            /\.pyc$/,
            /\.pyo$/,
            /\.pyd$/,
            /^node_modules\//,
            /^\.git\//,
            /^\.vscode\//,
            /^dist\//,
            /^build\//,
            /^\.pytest_cache\//,
            /^venv\//,
            /^env\//,
            /^\.env$/
        ];
        
        this.gitignorePatterns = [...defaultPatterns];
        
        try {
            const gitignorePath = path.join(this.workspaceRoot, '.gitignore');
            const gitignoreContent = await readFile(gitignorePath, 'utf-8');
            const lines = gitignoreContent.split('\n');
            
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed && !trimmed.startsWith('#')) {
                    // Convert gitignore pattern to regex (simplified)
                    const pattern = trimmed
                        .replace(/\./g, '\\.')
                        .replace(/\*/g, '.*')
                        .replace(/\?/g, '.');
                    this.gitignorePatterns.push(new RegExp(`^${pattern}`));
                }
            }
        } catch (error) {
            // Gitignore not found or error reading it
        }
    }

    private shouldIgnore(filePath: string): boolean {
        const relativePath = path.relative(this.workspaceRoot, filePath);
        return this.gitignorePatterns.some(pattern => pattern.test(relativePath));
    }

    private async analyzeFile(filePath: string) {
        if (this.processedFiles.has(filePath) || this.shouldIgnore(filePath)) {
            return;
        }
        
        this.processedFiles.add(filePath);
        
        const fileType = this.getFileType(filePath);
        if (fileType === 'unknown') {
            return;
        }
        
        // Add node for this file
        const nodeId = path.relative(this.workspaceRoot, filePath);
        this.nodes.set(nodeId, {
            id: nodeId,
            label: path.basename(filePath),
            fullPath: filePath,
            type: fileType
        });
        
        try {
            const content = await readFile(filePath, 'utf-8');
            const imports = await this.extractImports(content, filePath, fileType);
            
            for (const importPath of imports) {
                const resolvedPath = await this.resolveImport(importPath, filePath, fileType);
                if (resolvedPath && resolvedPath !== filePath) {
                    const targetId = path.relative(this.workspaceRoot, resolvedPath);
                    
                    // Add edge
                    this.edges.push({
                        source: nodeId,
                        target: targetId
                    });
                    
                    // Recursively analyze the imported file
                    await this.analyzeFile(resolvedPath);
                }
            }
        } catch (error) {
            console.error(`Error analyzing file ${filePath}:`, error);
        }
    }

    private getFileType(filePath: string): 'python' | 'javascript' | 'typescript' | 'unknown' {
        const ext = path.extname(filePath).toLowerCase();
        switch (ext) {
            case '.py':
                return 'python';
            case '.js':
            case '.jsx':
            case '.mjs':
                return 'javascript';
            case '.ts':
            case '.tsx':
                return 'typescript';
            default:
                return 'unknown';
        }
    }

    private async extractImports(content: string, filePath: string, fileType: string): Promise<string[]> {
        const imports: string[] = [];
        
        switch (fileType) {
            case 'python':
                imports.push(...this.extractPythonImports(content));
                break;
            case 'javascript':
            case 'typescript':
                imports.push(...this.extractJavaScriptImports(content));
                break;
        }
        
        return imports;
    }

    private extractPythonImports(content: string): string[] {
        const imports: string[] = [];
        
        // Match import statements
        const importRegex = /^\s*import\s+(\S+)/gm;
        const fromImportRegex = /^\s*from\s+(\S+)\s+import/gm;
        
        let match;
        while ((match = importRegex.exec(content)) !== null) {
            imports.push(match[1].split('.')[0]);
        }
        
        while ((match = fromImportRegex.exec(content)) !== null) {
            if (!match[1].startsWith('.')) {
                imports.push(match[1]);
            }
        }
        
        return imports;
    }

    private extractJavaScriptImports(content: string): string[] {
        const imports: string[] = [];
        
        // Match ES6 imports
        const es6ImportRegex = /import\s+(?:.*\s+from\s+)?['"]([^'"]+)['"]/g;
        // Match CommonJS requires
        const requireRegex = /require\s*\(['"]([^'"]+)['"]\)/g;
        
        let match;
        while ((match = es6ImportRegex.exec(content)) !== null) {
            imports.push(match[1]);
        }
        
        while ((match = requireRegex.exec(content)) !== null) {
            imports.push(match[1]);
        }
        
        return imports;
    }

    private async resolveImport(importPath: string, fromFile: string, fileType: string): Promise<string | null> {
        const fromDir = path.dirname(fromFile);
        
        switch (fileType) {
            case 'python':
                return this.resolvePythonImport(importPath, fromDir);
            case 'javascript':
            case 'typescript':
                return this.resolveJavaScriptImport(importPath, fromDir);
            default:
                return null;
        }
    }

    private async resolvePythonImport(importPath: string, fromDir: string): Promise<string | null> {
        const parts = importPath.split('.');
        
        // Try different possible locations
        const searchPaths = [
            this.workspaceRoot,
            path.join(this.workspaceRoot, 'src'),
            fromDir
        ];
        
        for (const searchPath of searchPaths) {
            const modulePath = path.join(searchPath, ...parts);
            
            // Try as a .py file
            const pyFile = modulePath + '.py';
            if (await this.fileExists(pyFile)) {
                return pyFile;
            }
            
            // Try as a package (__init__.py)
            const initFile = path.join(modulePath, '__init__.py');
            if (await this.fileExists(initFile)) {
                return initFile;
            }
        }
        
        return null;
    }

    private async resolveJavaScriptImport(importPath: string, fromDir: string): Promise<string | null> {
        // Handle relative imports
        if (importPath.startsWith('.')) {
            const fullPath = path.resolve(fromDir, importPath);
            
            // Try with different extensions
            const extensions = ['.js', '.jsx', '.ts', '.tsx', '.mjs', '/index.js', '/index.ts'];
            for (const ext of extensions) {
                const filePath = fullPath + ext;
                if (await this.fileExists(filePath)) {
                    return filePath;
                }
            }
            
            // Try as is (might already have extension)
            if (await this.fileExists(fullPath)) {
                return fullPath;
            }
        } else {
            // Handle node_modules imports
            const nodeModulesPath = path.join(this.workspaceRoot, 'node_modules', importPath);
            if (await this.fileExists(nodeModulesPath)) {
                // Don't analyze node_modules
                return null;
            }
            
            // Handle absolute imports (configured in tsconfig/jsconfig)
            const absolutePath = path.join(this.workspaceRoot, 'src', importPath);
            const extensions = ['.js', '.jsx', '.ts', '.tsx', '/index.js', '/index.ts'];
            for (const ext of extensions) {
                const filePath = absolutePath + ext;
                if (await this.fileExists(filePath)) {
                    return filePath;
                }
            }
        }
        
        return null;
    }

    private async fileExists(filePath: string): Promise<boolean> {
        try {
            const stats = await stat(filePath);
            return stats.isFile();
        } catch {
            return false;
        }
    }
}