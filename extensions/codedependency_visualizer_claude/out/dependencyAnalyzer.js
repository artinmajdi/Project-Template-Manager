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
        this.maxDepth = 1;
        this.fileLevels = new Map();
    }
    async analyzeDependencies(entryPoint, workspaceRoot, maxDepth = 1) {
        this.workspaceRoot = workspaceRoot;
        this.maxDepth = maxDepth;
        this.processedFiles.clear();
        this.nodes.clear();
        this.edges = [];
        this.fileLevels.clear();
        // Load gitignore patterns
        await this.loadGitignorePatterns();
        // Start analysis from entry point with level 0
        await this.analyzeFile(entryPoint, 0);
        // Ensure we have at least the entry point node
        const entryNodeId = path.relative(workspaceRoot, entryPoint);
        if (this.nodes.size === 0) {
            const fileType = this.getFileType(entryPoint);
            this.nodes.set(entryNodeId, {
                id: entryNodeId,
                label: path.basename(entryPoint),
                fullPath: entryPoint,
                type: fileType !== 'unknown' ? fileType : 'python'
            });
        }
        return {
            nodes: Array.from(this.nodes.values()),
            edges: this.edges,
            entryPoint: entryNodeId,
            maxDepth: this.maxDepth
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
        const ignored = this.gitignorePatterns.some(pattern => {
            const matches = pattern.test(relativePath);
            return matches;
        });
        return ignored;
    }
    async analyzeFile(filePath, currentLevel) {
        if (this.shouldIgnore(filePath)) {
            return;
        }
        // Check if we've exceeded the maximum depth
        if (currentLevel > this.maxDepth) {
            return;
        }
        const alreadyProcessed = this.processedFiles.has(filePath);
        // Get file type
        const fileType = this.getFileType(filePath);
        if (fileType === 'unknown') {
            return;
        }
        // Add node if not already processed
        if (!alreadyProcessed) {
            this.processedFiles.add(filePath);
            this.fileLevels.set(filePath, currentLevel);
            const nodeId = path.relative(this.workspaceRoot, filePath);
            this.nodes.set(nodeId, {
                id: nodeId,
                label: path.basename(filePath),
                fullPath: filePath,
                type: fileType
            });
        }
        // Process imports for this file
        try {
            const content = await readFile(filePath, 'utf-8');
            const imports = await this.extractImports(content, filePath, fileType);
            const nodeId = path.relative(this.workspaceRoot, filePath);
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
                    await this.analyzeFile(resolvedPath, currentLevel + 1);
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
                imports.push(...this.extractPythonImports(content, filePath));
                break;
            case 'javascript':
            case 'typescript':
                imports.push(...this.extractJavaScriptImports(content));
                break;
        }
        return imports;
    }
    extractPythonImports(content, filePath) {
        const imports = [];
        // Match import statements
        const importRegex = /^\s*import\s+(\S+)/gm;
        const fromImportRegex = /^\s*from\s+(\S+)\s+import/gm;
        let match;
        while ((match = importRegex.exec(content)) !== null) {
            // For 'import X.Y.Z', we want the full module path
            imports.push(match[1]);
        }
        while ((match = fromImportRegex.exec(content)) !== null) {
            const importPath = match[1];
            if (importPath.startsWith('.')) {
                // Handle relative imports
                const levels = (importPath.match(/\./g) || []).length;
                const modulePart = importPath.slice(levels);
                // Get the directory of the current file relative to workspace
                const fileDir = path.dirname(path.relative(this.workspaceRoot, filePath));
                const dirParts = fileDir.split(path.sep).filter(p => p);
                if (levels === 1) {
                    // from . import X or from .X import Y
                    if (modulePart) {
                        imports.push([...dirParts, modulePart].join('.'));
                    }
                }
                else {
                    // from .. import X or from ..X import Y
                    const baseParts = dirParts.slice(0, -(levels - 1));
                    if (baseParts.length >= 0) {
                        if (modulePart) {
                            imports.push([...baseParts, modulePart].join('.'));
                        }
                    }
                }
            }
            else {
                // Absolute import
                imports.push(importPath);
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