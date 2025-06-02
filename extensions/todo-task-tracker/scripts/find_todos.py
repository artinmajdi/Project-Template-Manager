#!/usr/bin/env python3
"""
TODO Finder Script
Searches for all TODO mentions in a workspace and extracts the associated tasks.
"""

import os
import re
import json
import fnmatch
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple, Set
import argparse

# Try to import pathspec for better gitignore handling, fallback to simple pattern matching
try:
    import pathspec
    HAS_PATHSPEC = True
except ImportError:
    HAS_PATHSPEC = False

class TodoFinder:
    def __init__(self, root_path: str = ".", output_format: str = "json"):
        self.root_path = Path(root_path)
        self.output_format = output_format
        self.todos = []
        self._quiet_mode = False
        self._original_print = print

        # Initialize gitignore patterns (will be loaded later)
        self.gitignore_spec = None
        self.gitignore_patterns = set()
        self._gitignore_loaded = False

        # Patterns to match TODO comments in various formats
        self.todo_patterns = [
            # Single-line comments (// or #)
            r'(?://|#)\s*(?:TODO|Todo|todo|TO-DO|To-Do|to-do|FIXME|FIX ME|fix me)\s*[:：]?\s*(.+?)(?:\n|$)',
            # Multi-line comments (/* */ or <!-- -->)
            r'(?:/\*|<!--)\s*(?:TODO|Todo|todo|TO-DO|To-Do|to-do|FIXME|FIX ME|fix me)\s*[:：]?\s*(.+?)(?:\*/|-->)',
            # Python docstring style
            r'"""\s*(?:TODO|Todo|todo|TO-DO|To-Do|to-do|FIXME|FIX ME|fix me)\s*[:：]?\s*(.+?)"""',
            r"'''\s*(?:TODO|Todo|todo|TO-DO|To-Do|to-do|FIXME|FIX ME|fix me)\s*[:：]?\s*(.+?)'''",
            # Without comment markers (for plain text files)
            r'^(?:TODO|Todo|todo|TO-DO|To-Do|to-do|FIXME|FIX ME|fix me)\s*[:：]?\s*(.+?)(?:\n|$)',
        ]

        # File extensions to search
        self.searchable_extensions = {
            '.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.c', '.cpp', '.cs',
            '.go', '.rs', '.php', '.rb', '.swift', '.kt', '.scala', '.r',
            '.html', '.css', '.scss', '.less', '.vue', '.svelte',
            '.md', '.txt', '.rst', '.tex', '.xml', '.yaml', '.yml', '.json',
            '.sh', '.bash', '.zsh', '.ps1', '.bat', '.cmd',
            '.sql', '.dockerfile', '.makefile', ''  # '' for files without extension
        }

        # Directories to skip (in addition to gitignore)
        self.skip_dirs = {
            '.git', '.svn', '.hg', 'node_modules', '__pycache__', '.pytest_cache',
            'venv', 'env', '.env', 'dist', 'build', 'target', 'out', '.idea',
            '.vscode', '.vs', 'bin', 'obj', 'packages', '.gradle', '.m2',
            'coverage', '.nyc_output', '.next', '.nuxt', '.cache'
        }

    def _load_gitignore(self):
        """Load and parse .gitignore file if it exists."""
        gitignore_path = self.root_path / '.gitignore'

        if not gitignore_path.exists():
            self._print("📝 No .gitignore file found, using default ignore patterns")
            return

        try:
            with open(gitignore_path, 'r', encoding='utf-8') as f:
                gitignore_content = f.read()

            if HAS_PATHSPEC:
                # Use pathspec for proper gitignore handling
                self.gitignore_spec = pathspec.PathSpec.from_lines('gitwildmatch', gitignore_content.splitlines())
                self._print(f"✅ Loaded .gitignore with pathspec support")
            else:
                # Fallback to simple pattern matching
                lines = gitignore_content.splitlines()
                for line in lines:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        # Remove leading slash and add to patterns
                        pattern = line.lstrip('/')
                        self.gitignore_patterns.add(pattern)
                self._print("💡 Tip: Install 'pathspec' for better .gitignore support: pip install pathspec")
                self._print(f"✅ Loaded .gitignore with {len(self.gitignore_patterns)} patterns (basic support)")

        except Exception as e:
            self._print(f"⚠️  Error reading .gitignore: {e}")

    def _should_ignore_path(self, path: Path) -> bool:
        """Check if a path should be ignored based on gitignore rules."""
        # Convert to relative path from root
        try:
            rel_path = path.relative_to(self.root_path)
        except ValueError:
            # Path is not relative to root, don't ignore
            return False

        # Convert to string with forward slashes (git style)
        rel_path_str = str(rel_path).replace('\\', '/')

        if HAS_PATHSPEC and self.gitignore_spec:
            # Use pathspec for accurate gitignore matching
            return self.gitignore_spec.match_file(rel_path_str)
        else:
            # Fallback to simple pattern matching
            for pattern in self.gitignore_patterns:
                # Simple wildcard matching
                if fnmatch.fnmatch(rel_path_str, pattern):
                    return True
                # Check if any parent directory matches
                for parent in rel_path.parents:
                    try:
                        parent_str = str(parent.relative_to(self.root_path)).replace('\\', '/')
                        if fnmatch.fnmatch(parent_str, pattern):
                            return True
                    except ValueError:
                        # Parent is not relative to root, skip
                        continue
            return False

    def _print(self, *args, **kwargs):
        """Print function that respects quiet mode."""
        if self._quiet_mode:
            import sys
            kwargs['file'] = sys.stderr
        self._original_print(*args, **kwargs)

    def find_todos(self) -> List[Dict]:
        """Find all TODOs in the workspace."""
        # Load gitignore patterns if not already loaded
        if not self._gitignore_loaded:
            self._load_gitignore()
            self._gitignore_loaded = True

        self._print(f"🔍 Searching for TODOs in: {self.root_path}")

        for root, dirs, files in os.walk(self.root_path):
            root_path = Path(root)

            # Filter out directories that should be ignored
            dirs[:] = [
                d for d in dirs
                if d not in self.skip_dirs and not self._should_ignore_path(root_path / d)
            ]

            for file in files:
                file_path = root_path / file

                # Skip files that should be ignored
                if self._should_ignore_path(file_path):
                    continue

                # Skip files with unwanted extensions
                if file_path.suffix.lower() not in self.searchable_extensions and file_path.suffix != '':
                    continue

                # Skip binary files
                if self._is_binary_file(file_path):
                    continue

                try:
                    self._search_file(file_path)
                except Exception as e:
                    self._print(f"⚠️  Error reading {file_path}: {e}")

        self._print(f"\n✅ Found {len(self.todos)} TODOs")
        return self.todos

    def _is_binary_file(self, file_path: Path) -> bool:
        """Check if a file is binary."""
        try:
            with open(file_path, 'rb') as f:
                chunk = f.read(1024)
                return b'\0' in chunk
        except:
            return True

    def _search_file(self, file_path: Path):
        """Search for TODOs in a single file."""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Search with all patterns
            for pattern in self.todo_patterns:
                matches = re.finditer(pattern, content, re.MULTILINE | re.IGNORECASE)

                for match in matches:
                    todo_text = match.group(1).strip()
                    if todo_text:  # Skip empty TODOs
                        line_num = content[:match.start()].count('\n') + 1

                        # Extract the whole line for context
                        lines = content.splitlines()
                        context_line = lines[line_num - 1] if line_num <= len(lines) else ""

                        self.todos.append({
                            'id': len(self.todos) + 1,
                            'file': str(file_path.relative_to(self.root_path)),
                            'line': line_num,
                            'text': todo_text,
                            'context': context_line.strip(),
                            'category': self._categorize_todo(todo_text),
                            'timestamp': datetime.now().isoformat()
                        })
        except Exception as e:
            pass  # Silently skip files that can't be read

    def _categorize_todo(self, text: str) -> str:
        """Categorize TODO based on keywords."""
        text_lower = text.lower()

        if any(word in text_lower for word in ['bug', 'fix', 'error', 'issue']):
            return 'bug'
        elif any(word in text_lower for word in ['feature', 'implement', 'add']):
            return 'feature'
        elif any(word in text_lower for word in ['refactor', 'clean', 'optimize']):
            return 'refactor'
        elif any(word in text_lower for word in ['document', 'docs', 'comment']):
            return 'documentation'
        elif any(word in text_lower for word in ['test', 'testing', 'unit test']):
            return 'testing'
        else:
            return 'general'

    def save_results(self, output_file: str = None):
        """Save the TODO list to a file."""
        if not output_file:
            output_file = f"todos_workspace"

        if self.output_format == 'json':
            self._save_json(output_file + '.json')
        elif self.output_format == 'markdown':
            self._save_markdown(output_file + '.md')
        elif self.output_format == 'txt':
            self._save_text(output_file + '.txt')
        elif self.output_format == 'all':
            self._save_json(output_file + '.json')
            self._save_markdown(output_file + '.md')
            self._save_text(output_file + '.txt')

    def _save_json(self, filename: str):
        """Save results as JSON."""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump({
                'workspace': str(self.root_path),
                'generated_at': datetime.now().isoformat(),
                'total_todos': len(self.todos),
                'todos': self.todos
            }, f, indent=2, ensure_ascii=False)
        self._print(f"📄 Saved JSON: {filename}")

    def _save_markdown(self, filename: str):
        """Save results as Markdown."""
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"# TODO List\n\n")
            f.write(f"**Workspace:** `{self.root_path}`  \n")
            f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  \n")
            f.write(f"**Total TODOs:** {len(self.todos)}\n\n")

            # Group by category
            categories = {}
            for todo in self.todos:
                cat = todo['category']
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(todo)

            for category, todos in categories.items():
                f.write(f"## {category.title()} ({len(todos)})\n\n")
                for todo in todos:
                    f.write(f"- [ ] **{todo['text']}**\n")
                    f.write(f"  - 📁 `{todo['file']}:{todo['line']}`\n")
                    if todo['context']:
                        f.write(f"  - 📝 Context: `{todo['context'][:100]}...`\n")
                    f.write("\n")

        self._print(f"📄 Saved Markdown: {filename}")

    def _save_text(self, filename: str):
        """Save results as plain text."""
        with open(filename, 'w', encoding='utf-8') as f:
            f.write("TODO LIST\n")
            f.write("=" * 80 + "\n\n")
            f.write(f"Workspace: {self.root_path}\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Total TODOs: {len(self.todos)}\n")
            f.write("=" * 80 + "\n\n")

            for i, todo in enumerate(self.todos, 1):
                f.write(f"{i}. {todo['text']}\n")
                f.write(f"   File: {todo['file']}:{todo['line']}\n")
                f.write(f"   Category: {todo['category']}\n")
                f.write("-" * 40 + "\n")

        self._print(f"📄 Saved Text: {filename}")

    def print_summary(self):
        """Print a summary of findings."""
        if not self.todos:
            print("\n📭 No TODOs found!")
            return

        print("\n" + "=" * 80)
        print("TODO SUMMARY")
        print("=" * 80)

        # Count by category
        categories = {}
        for todo in self.todos:
            cat = todo['category']
            categories[cat] = categories.get(cat, 0) + 1

        print("\n📊 By Category:")
        for cat, count in sorted(categories.items(), key=lambda x: x[1], reverse=True):
            print(f"  - {cat.title()}: {count}")

        # Count by file
        files = {}
        for todo in self.todos:
            file = todo['file']
            files[file] = files.get(file, 0) + 1

        print("\n📁 Top Files with TODOs:")
        for file, count in sorted(files.items(), key=lambda x: x[1], reverse=True)[:10]:
            print(f"  - {file}: {count} TODOs")

        # Sample TODOs
        print("\n📝 Sample TODOs:")
        for todo in self.todos[:5]:
            print(f"  - {todo['text'][:80]}...")
            print(f"    ({todo['file']}:{todo['line']})")


def main():
    parser = argparse.ArgumentParser(description="Find all TODO comments in your workspace")
    parser.add_argument('path', nargs='?', default='.', help='Path to search (default: current directory)')
    parser.add_argument('-o', '--output', help='Output filename (without extension)')
    parser.add_argument('-f', '--format', choices=['json', 'markdown', 'txt', 'all'],
                       default='markdown', help='Output format (default: markdown)')
    parser.add_argument('--no-summary', action='store_true', help='Skip printing summary')
    parser.add_argument('--extension-mode', action='store_true', help='Output JSON to stdout for VSCode extension integration')

    args = parser.parse_args()

        # Create finder and search
    finder = TodoFinder(args.path, args.format)

    # In extension mode, suppress progress messages
    if args.extension_mode:
        # Set quiet mode before any operations
        finder._quiet_mode = True

    finder.find_todos()

    if args.extension_mode:
        # Output JSON directly to stdout for extension consumption
        import json
        output_data = {
            'workspace': str(finder.root_path),
            'generated_at': datetime.now().isoformat(),
            'total_todos': len(finder.todos),
            'todos': finder.todos
        }
        finder._original_print(json.dumps(output_data, indent=2, ensure_ascii=False))
        return

        # Output JSON directly to stdout for extension consumption
        import json
        output_data = {
            'workspace': str(finder.root_path),
            'generated_at': datetime.now().isoformat(),
            'total_todos': len(finder.todos),
            'todos': finder.todos
        }
        print(json.dumps(output_data, indent=2, ensure_ascii=False))
        return

    # Save results (normal mode)
    if finder.todos:
        finder.save_results(args.output)

    # Print summary
    if not args.no_summary:
        finder.print_summary()


if __name__ == "__main__":
    main()
