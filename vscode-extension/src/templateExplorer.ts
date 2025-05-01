import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

// Define template node types
export class TemplateTreeItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly templatePath: string,
        public readonly isFile: boolean = false,
        public readonly isRoot: boolean = false,
        public readonly contextValue: string = ''
    ) {
        super(label, collapsibleState);

        // Set icon based on item type
        if (isFile) {
            this.iconPath = new vscode.ThemeIcon('file');
            this.contextValue = 'templateFile';
        } else if (isRoot) {
            this.iconPath = new vscode.ThemeIcon('folder-opened');
        } else {
            this.iconPath = new vscode.ThemeIcon('folder');
            if (!isRoot && contextValue !== 'category') {
                this.contextValue = 'templateFolder';
            }
        }
    }
}

export class TemplateExplorerProvider implements vscode.TreeDataProvider<TemplateTreeItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<TemplateTreeItem | undefined | null | void> = new vscode.EventEmitter<TemplateTreeItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<TemplateTreeItem | undefined | null | void> = this._onDidChangeTreeData.event;

    constructor(private workspaceRoot: string, private extensionContext: vscode.ExtensionContext) {}

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: TemplateTreeItem): vscode.TreeItem {
        return element;
    }

    async getChildren(element?: TemplateTreeItem): Promise<TemplateTreeItem[]> {
        // If no element is provided, we're at the root level
        if (!element) {
            const items: TemplateTreeItem[] = [];

            // Get all templates
            const templatesDir = this.getTemplatesDir();
            if (fs.existsSync(templatesDir)) {
                const templates = fs.readdirSync(templatesDir, { withFileTypes: true })
                    .filter(dirent => dirent.isDirectory())
                    .map(dirent => new TemplateTreeItem(
                        dirent.name,
                        vscode.TreeItemCollapsibleState.Collapsed,
                        path.join(templatesDir, dirent.name),
                        false,
                        false,
                        'template'
                    ));

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

                    return new TemplateTreeItem(
                        entry.name,
                        isFile ? vscode.TreeItemCollapsibleState.None : vscode.TreeItemCollapsibleState.Collapsed,
                        itemPath,
                        isFile,
                        false,
                        isFile ? 'templateFile' : 'templateFolder'
                    );
                });
        }

        return [];
    }

    // Helper function to get templates directory path
    private getTemplatesDir(): string {
        return path.join(this.extensionContext.globalStorageUri.fsPath, 'templates');
    }
}

// Template management class
export class TemplateManager {
    private templatesDir: string;

    constructor(private context: vscode.ExtensionContext) {
        this.templatesDir = path.join(context.globalStorageUri.fsPath, 'templates');
        this.ensureTemplatesDirExists();
    }

    private ensureTemplatesDirExists(): void {
        if (!fs.existsSync(this.templatesDir)) {
            fs.mkdirSync(this.templatesDir, { recursive: true });
        }
    }

    // Install a template from source directory with a specific name
    async installTemplate(sourceTemplateDir: string, templateName: string): Promise<void> {
        // Create the template directory in the templates directory
        const targetDir = path.join(this.templatesDir, templateName);

        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });

            // Copy files and directories from the sourceTemplateDir to the target directory
            await this.copyFolderRecursive(sourceTemplateDir, targetDir);
        }
    }

    // Install default template example (for backward compatibility)
    async installDefaultTemplate(defaultTemplateDir: string): Promise<void> {
        return this.installTemplate(defaultTemplateDir, 'pythonic_template');
    }

    // Helper function to recursively copy a directory
    private async copyFolderRecursive(source: string, target: string): Promise<void> {
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
            } else {
                // Copy the file
                fs.copyFileSync(sourcePath, targetPath);
            }
        }
    }

    // Add a new template from a directory
    async addTemplate(sourcePath: string, templateName?: string): Promise<string | undefined> {
        if (!fs.existsSync(sourcePath)) {
            return undefined;
        }

        const name = templateName || path.basename(sourcePath);
        const targetDir = path.join(this.templatesDir, name);

        // Check if template with this name already exists
        if (fs.existsSync(targetDir)) {
            const overwrite = await vscode.window.showWarningMessage(
                `Template "${name}" already exists. Overwrite?`,
                { modal: true },
                'Overwrite'
            );

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
    deleteTemplate(templateName: string): boolean {
        const templatePath = path.join(this.templatesDir, templateName);

        if (fs.existsSync(templatePath)) {
            this.deleteTemplateFolder(templatePath);
            return true;
        }

        return false;
    }

    // Helper method to delete a folder recursively
    private deleteTemplateFolder(folderPath: string): void {
        if (fs.existsSync(folderPath)) {
            fs.rmSync(folderPath, { recursive: true, force: true });
        }
    }

    // Get path to a specific template
    getTemplatePath(templateName: string): string {
        return path.join(this.templatesDir, templateName);
    }
}
