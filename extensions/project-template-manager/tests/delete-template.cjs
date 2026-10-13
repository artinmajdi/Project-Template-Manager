// Run after npm run compile: node --test tests/delete-template.cjs
const assert = require('node:assert/strict');
const { test } = require('node:test');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const Module = require('node:module');

test('only top-level templates can be deleted, after confirmation', async () => {
    const storage = fs.mkdtempSync(path.join(os.tmpdir(), 'template-delete-'));
    const commands = new Map();
    const errors = [];
    let confirmations = 0;
    let response;
    const vscode = {
        TreeItem: class { constructor(label) { this.label = label; } },
        ThemeIcon: class {},
        TreeItemCollapsibleState: { None: 0, Collapsed: 1 },
        EventEmitter: class { event = () => {}; fire() {} },
        workspace: {},
        extensions: { getExtension: () => ({ packageJSON: { version: '1.8.1' } }) },
        window: {
            registerTreeDataProvider() {},
            showErrorMessage(message) { errors.push(message); },
            showInformationMessage() {},
            async showWarningMessage() { confirmations++; return response; }
        },
        commands: { registerCommand(name, callback) { commands.set(name, callback); return {}; } }
    };
    const originalLoad = Module._load;
    Module._load = function (name, ...args) {
        return name === 'vscode' ? vscode : originalLoad.call(this, name, ...args);
    };
    try {
        const { TemplateTreeItem, TemplateExplorerProvider } = require('../out/templateExplorer');
        const { activate } = require('../out/extension');
        const context = {
            globalStorageUri: { fsPath: storage }, extensionPath: storage,
            globalState: { get: () => '1.8.1' }, subscriptions: []
        };
        const root = path.join(storage, 'templates', 'example');
        fs.mkdirSync(path.join(root, 'nested'), { recursive: true });
        fs.writeFileSync(path.join(root, 'file.txt'), 'keep');
        const provider = new TemplateExplorerProvider('', context);
        const [template] = await provider.getChildren();
        assert.equal(template.contextValue, 'template');
        const children = await provider.getChildren(template);
        assert.deepEqual(children.map(item => item.contextValue).sort(), ['templateFile', 'templateFolder']);
        const menu = require('../package.json').contributes.menus['view/item/context']
            .find(item => item.command === 'project-template-manager.deleteTemplate');
        assert.equal(menu.when, 'view == projectTemplateExplorer && viewItem == template');
        activate(context);
        const remove = commands.get('project-template-manager.deleteTemplate');
        for (const invalid of [undefined, ...children, new TemplateTreeItem('category', 1, root, false, false, 'category')]) {
            await remove(invalid);
        }
        assert.equal(errors.length, 4);
        assert.equal(confirmations, 0);
        assert.ok(fs.existsSync(root));
        await remove(template); // dismiss confirmation
        assert.ok(fs.existsSync(root));
        response = 'Delete';
        await remove(template);
        assert.equal(confirmations, 2);
        assert.equal(fs.existsSync(root), false);
    } finally {
        Module._load = originalLoad;
        fs.rmSync(storage, { recursive: true, force: true });
    }
});
