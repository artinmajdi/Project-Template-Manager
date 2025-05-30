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
exports.DependencyAnalyzer = void 0;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const util_1 = require("util");
const readFile = (0, util_1.promisify)(fs.readFile);
const readdir = (0, util_1.promisify)(fs.readdir);
const stat = (0, util_1.promisify)(fs.stat);
class DependencyAnalyzer {
    constructor() {
        this.processedFiles = new Set();
        this.nodes = new Map();
        this.edges = [];
        this.workspaceRoot = '';
        this.gitignorePatterns = [];
    }
    async analyzeDependencies(entryPoint, workspaceRoot) {
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
    async loadGitignorePatterns() {
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
        }
        catch (error) {
            // Gitignore not found or error reading it
        }
    }
    shouldIgnore(filePath) {
        const relativePath = path.relative(this.workspaceRoot, filePath);
        return this.gitignorePatterns.some(pattern => pattern.test(relativePath));
    }
    async analyzeFile(filePath) {
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
        }
        catch (error) {
            console.error(`Error analyzing file ${filePath}:`, error);
        }
    }
    getFileType(filePath) {
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
    async extractImports(content, filePath, fileType) {
        const imports = [];
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
    extractPythonImports(content) {
        const imports = [];
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
    extractJavaScriptImports(content) {
        const imports = [];
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
    async resolveImport(importPath, fromFile, fileType) {
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
    async resolvePythonImport(importPath, fromDir) {
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
    async resolveJavaScriptImport(importPath, fromDir) {
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
        }
        else {
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
    async fileExists(filePath) {
        try {
            const stats = await stat(filePath);
            return stats.isFile();
        }
        catch {
            return false;
        }
    }
}
exports.DependencyAnalyzer = DependencyAnalyzer;
//# sourceMappingURL=dependencyAnalyzer.js.map