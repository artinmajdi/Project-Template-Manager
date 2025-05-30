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
exports.TemplateManager = exports.TemplateExplorerProvider = exports.TemplateTreeItem = void 0;
const vscode = __importStar(require("vscode"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
// Define template node types
class TemplateTreeItem extends vscode.TreeItem {
    label;
    collapsibleState;
    templatePath;
    isFile;
    isRoot;
    contextValue;
    constructor(label, collapsibleState, templatePath, isFile = false, isRoot = false, contextValue = '') {
        super(label, collapsibleState);
        this.label = label;
        this.collapsibleState = collapsibleState;
        this.templatePath = templatePath;
        this.isFile = isFile;
        this.isRoot = isRoot;
        this.contextValue = contextValue;
        // Set icon based on item type
        if (isFile) {
            this.iconPath = new vscode.ThemeIcon('file');
            this.contextValue = 'templateFile';
        }
        else if (isRoot) {
            this.iconPath = new vscode.ThemeIcon('folder-opened');
        }
        else {
            this.iconPath = new vscode.ThemeIcon('folder');
            if (!isRoot && contextValue !== 'category') {
                this.contextValue = 'templateFolder';
            }
        }
    }
}
exports.TemplateTreeItem = TemplateTreeItem;
class TemplateExplorerProvider {
    workspaceRoot;
    extensionContext;
    _onDidChangeTreeData = new vscode.EventEmitter();
    onDidChangeTreeData = this._onDidChangeTreeData.event;
    constructor(workspaceRoot, extensionContext) {
        this.workspaceRoot = workspaceRoot;
        this.extensionContext = extensionContext;
    }
    refresh() {
        this._onDidChangeTreeData.fire();
    }
    getTreeItem(element) {
        return element;
    }
    async getChildren(element) {
        // If no element is provided, we're at the root level
        if (!element) {
            const items = [];
            // Get all templates
            const templatesDir = this.getTemplatesDir();
            if (fs.existsSync(templatesDir)) {
                const templates = fs.readdirSync(templatesDir, { withFileTypes: true })
                    .filter(dirent => dirent.isDirectory())
                    .map(dirent => new TemplateTreeItem(dirent.name, vscode.TreeItemCollapsibleState.Collapsed, path.join(templatesDir, dirent.name), false, false, 'template'));
                items.push(...templates);
            }
            return items;
        }
        // If the element is a template or folder, show its children
        if (fs.existsSync(element.templatePath)) {
            return fs.readdirSync(element.templatePath, { withFileTypes: true })
                .map(entry => {
                const itemPath = path.join(element.templatePath, entry.name);
                const isFile = entry.isFile();
                return new TemplateTreeItem(entry.name, isFile ? vscode.TreeItemCollapsibleState.None : vscode.TreeItemCollapsibleState.Collapsed, itemPath, isFile, false, isFile ? 'templateFile' : 'templateFolder');
            });
        }
        return [];
    }
    // Helper function to get templates directory path
    getTemplatesDir() {
        return path.join(this.extensionContext.globalStorageUri.fsPath, 'templates');
    }
}
exports.TemplateExplorerProvider = TemplateExplorerProvider;
// Template management class
class TemplateManager {
    context;
    templatesDir;
    constructor(context) {
        this.context = context;
        this.templatesDir = path.join(context.globalStorageUri.fsPath, 'templates');
        this.ensureTemplatesDirExists();
    }
    ensureTemplatesDirExists() {
        if (!fs.existsSync(this.templatesDir)) {
            fs.mkdirSync(this.templatesDir, { recursive: true });
        }
    }
    // Install a template from source directory with a specific name
    async installTemplate(sourceTemplateDir, templateName) {
        // Create the template directory in the templates directory
        const targetDir = path.join(this.templatesDir, templateName);
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
            // Copy files and directories from the sourceTemplateDir to the target directory
            await this.copyFolderRecursive(sourceTemplateDir, targetDir);
        }
    }
    // Install default template example (for backward compatibility)
    async installDefaultTemplate(defaultTemplateDir) {
        return this.installTemplate(defaultTemplateDir, 'pythonic_template');
    }
    // Helper function to recursively copy a directory
    async copyFolderRecursive(source, target) {
        // Create the target directory if it doesn't exist
        if (!fs.existsSync(target)) {
            fs.mkdirSync(target, { recursive: true });
        }
        // Read the source directory
        const entries = fs.readdirSync(source, { withFileTypes: true });
        for (const entry of entries) {
            const sourcePath = path.join(source, entry.name);
            const targetPath = path.join(target, entry.name);
            if (entry.isDirectory()) {
                // Recursively copy the directory
                await this.copyFolderRecursive(sourcePath, targetPath);
            }
            else {
                // Copy the file
                fs.copyFileSync(sourcePath, targetPath);
            }
        }
    }
    // Add a new template from a directory
    async addTemplate(sourcePath, templateName) {
        if (!fs.existsSync(sourcePath)) {
            return undefined;
        }
        const name = templateName || path.basename(sourcePath);
        const targetDir = path.join(this.templatesDir, name);
        // Check if template with this name already exists
        if (fs.existsSync(targetDir)) {
            const overwrite = await vscode.window.showWarningMessage(`Template "${name}" already exists. Overwrite?`, { modal: true }, 'Overwrite');
            if (overwrite !== 'Overwrite') {
                return undefined;
            }
            // Remove existing template
            this.deleteTemplateFolder(targetDir);
        }
        // Create template directory and copy contents
        fs.mkdirSync(targetDir, { recursive: true });
        await this.copyFolderRecursive(sourcePath, targetDir);
        return name;
    }
    // Delete a template
    deleteTemplate(templateName) {
        const templatePath = path.join(this.templatesDir, templateName);
        if (fs.existsSync(templatePath)) {
            this.deleteTemplateFolder(templatePath);
            return true;
        }
        return false;
    }
    // Helper method to delete a folder recursively
    deleteTemplateFolder(folderPath) {
        if (fs.existsSync(folderPath)) {
            fs.rmSync(folderPath, { recursive: true, force: true });
        }
    }
    // Get path to a specific template
    getTemplatePath(templateName) {
        return path.join(this.templatesDir, templateName);
    }
}
exports.TemplateManager = TemplateManager;
//# sourceMappingURL=templateExplorer.js.map