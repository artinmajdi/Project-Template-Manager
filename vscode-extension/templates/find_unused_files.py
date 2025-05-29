#!/usr/bin/env python3
"""
Unused File Finder
==================
An interactive tool to identify unused Python files in your project by tracing imports from main entry points.

Features:
- Interactive mode to select entry points
- Respects .gitignore files
- Comprehensive import tracing
- Clear reporting of unused files
"""

import ast
import os
import sys
import argparse
from pathlib import Path
from typing import Set, Dict, List, Tuple, Optional
import importlib.util
from collections import defaultdict
import fnmatch
import re


class GitignoreParser:
    """Simple gitignore parser to filter out ignored files."""

    def __init__(self, project_root: Path):
        """
        Initialize the GitignoreParser.

        :param project_root: The root directory of the project
        """
        self.project_root = project_root
        self.patterns = []
        self._load_gitignore()

    def _load_gitignore(self):
        """Load patterns from .gitignore file."""
        gitignore_path = self.project_root / '.gitignore'
        if not gitignore_path.exists():
            return

        try:
            with open(gitignore_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    # Skip empty lines and comments
                    if not line or line.startswith('#'):
                        continue

                    # Handle negation patterns (not fully implemented)
                    if line.startswith('!'):
                        continue

                    # Convert gitignore pattern to regex
                    pattern = line

                    # Handle directory patterns
                    if pattern.endswith('/'):
                        pattern = pattern[:-1] + '/**'

                    # Convert to regex pattern
                    regex_pattern = self._gitignore_to_regex(pattern)
                    self.patterns.append(regex_pattern)

        except Exception as e:
            print(f"Warning: Could not parse .gitignore: {e}", file=sys.stderr)

    def _gitignore_to_regex(self, pattern: str) -> re.Pattern:
        """Convert gitignore pattern to regex."""
        # Escape special regex characters except * and ?
        pattern = re.escape(pattern)
        pattern = pattern.replace(r'\*\*', '.*')  # ** matches everything
        pattern = pattern.replace(r'\*', '[^/]*')  # * matches anything except /
        pattern = pattern.replace(r'\?', '.')      # ? matches single character

        # If pattern doesn't start with /, it can match at any level
        if not pattern.startswith('/'):
            pattern = '.*/' + pattern
        else:
            pattern = pattern[1:]  # Remove leading /

        return re.compile(pattern)

    def is_ignored(self, file_path: Path) -> bool:
        """Check if a file should be ignored."""
        try:
            relative_path = file_path.relative_to(self.project_root)
            path_str = str(relative_path.as_posix())

            for pattern in self.patterns:
                if pattern.match(path_str):
                    return True

            # Also check if any parent directory is ignored
            for parent in relative_path.parents:
                parent_str = str(parent.as_posix())
                if parent_str and parent_str != '.':
                    for pattern in self.patterns:
                        if pattern.match(parent_str):
                            return True

        except ValueError:
            # File is outside project root
            pass

        return False


class ImportTracer:
    """Traces all imports starting from entry points to find used files."""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.gitignore = GitignoreParser(project_root)
        self.used_files: Dict[str, Set[Path]] = defaultdict(set)
        self.all_python_files: Set[Path] = set()
        self._find_all_python_files()

    def _find_all_python_files(self):
        """Find all Python files in the project, respecting .gitignore."""
        for root, dirs, files in os.walk(self.project_root):
            root_path = Path(root)

            # Skip common directories that shouldn't be analyzed
            dirs[:] = [d for d in dirs if d not in {
                '__pycache__', '.git', '.venv', 'venv', 'env',
                'node_modules', '.tox', '.pytest_cache', '.mypy_cache',
                'build', 'dist', '.egg-info'
            }]

            # Also skip gitignored directories
            dirs[:] = [d for d in dirs if not self.gitignore.is_ignored(root_path / d)]

            for file in files:
                if file.endswith('.py'):
                    file_path = root_path / file
                    # Skip if gitignored
                    if not self.gitignore.is_ignored(file_path):
                        self.all_python_files.add(file_path.resolve())

    def _parse_imports(self, file_path: Path) -> List[str]:
        """Parse a Python file and extract all imports."""
        imports = []

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            tree = ast.parse(content)

            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.append(alias.name)
                elif isinstance(node, ast.ImportFrom):
                    if node.module:
                        imports.append(node.module)
                    # Handle relative imports
                    if node.level > 0:
                        # Calculate the package for relative imports
                        parent_parts = file_path.parent.parts
                        root_parts = self.project_root.parts
                        if len(parent_parts) > len(root_parts):
                            package_parts = parent_parts[len(root_parts):]
                            if node.level <= len(package_parts):
                                base_package = '.'.join(package_parts[:-node.level+1])
                                if node.module:
                                    imports.append(f"{base_package}.{node.module}")
                                else:
                                    imports.append(base_package)
        except Exception as e:
            print(f"Warning: Could not parse {file_path}: {e}", file=sys.stderr)

        return imports

    def _resolve_import_to_file(self, import_name: str, current_file: Path) -> Set[Path]:
        """Resolve an import name to actual file paths."""
        resolved_files = set()

        # Split the import into parts
        parts = import_name.split('.')

        # Try different combinations to find the file
        for i in range(len(parts), 0, -1):
            potential_module = '.'.join(parts[:i])
            remaining = parts[i:]

            # Try to find as a file
            for root in [self.project_root, current_file.parent]:
                # Direct file import
                file_path = root / '/'.join(parts[:i])

                # Check for .py file
                py_file = file_path.with_suffix('.py')
                if py_file.exists() and py_file.is_file():
                    resolved_files.add(py_file.resolve())

                # Check for __init__.py in directory
                init_file = file_path / '__init__.py'
                if init_file.exists() and init_file.is_file():
                    resolved_files.add(init_file.resolve())

                    # If there are remaining parts, check for submodules
                    if remaining:
                        submodule_path = file_path / '/'.join(remaining)
                        sub_py = submodule_path.with_suffix('.py')
                        if sub_py.exists():
                            resolved_files.add(sub_py.resolve())

                        sub_init = submodule_path / '__init__.py'
                        if sub_init.exists():
                            resolved_files.add(sub_init.resolve())

        # Also check if it's a package with all its files
        package_path = self.project_root / '/'.join(parts)
        if package_path.exists() and package_path.is_dir():
            # Add all Python files in the package
            for py_file in package_path.rglob('*.py'):
                resolved_files.add(py_file.resolve())

        return resolved_files

    def trace_imports(self, entry_point: Path) -> Set[Path]:
        """Trace all imports starting from an entry point."""
        to_process = {entry_point.resolve()}
        processed = set()
        used = set()

        while to_process:
            current_file = to_process.pop()
            if current_file in processed:
                continue

            processed.add(current_file)
            used.add(current_file)

            # Get imports from this file
            imports = self._parse_imports(current_file)

            # Resolve imports to files
            for import_name in imports:
                resolved_files = self._resolve_import_to_file(import_name, current_file)
                for resolved_file in resolved_files:
                    if resolved_file in self.all_python_files and resolved_file not in processed:
                        to_process.add(resolved_file)

        return used

    def analyze(self, entry_points: List[Path]) -> Dict[str, Set[Path]]:
        """Analyze the project starting from given entry points."""
        results = {}

        for entry_point in entry_points:
            if entry_point.exists() and entry_point.is_file():
                used_files = self.trace_imports(entry_point)
                results[str(entry_point)] = used_files
            else:
                print(f"Warning: Entry point {entry_point} does not exist", file=sys.stderr)

        return results


def find_default_entry_points(project_root: Path) -> List[Path]:
    """Find default entry points based on common patterns."""
    patterns = [
        '*/visualization/app.py',
        '*/main.py',
        '*cli.py'
    ]

    entry_points = []
    gitignore = GitignoreParser(project_root)

    for pattern in patterns:
        if '*/' in pattern:
            # Handle patterns with directory wildcards
            parts = pattern.split('/')
            for root, dirs, files in os.walk(project_root):
                root_path = Path(root)
                if parts[-1] in files:
                    # Check if the path matches the pattern
                    if len(parts) == 2 or (len(parts) > 2 and parts[-2] in root_path.parts):
                        file_path = root_path / parts[-1]
                        if not gitignore.is_ignored(file_path):
                            entry_points.append(file_path)
        else:
            # Handle simple wildcard patterns
            for file_path in project_root.rglob(pattern):
                if file_path.is_file() and not gitignore.is_ignored(file_path):
                    entry_points.append(file_path)

    return entry_points


def interactive_select_entry_points(project_root: Path) -> List[Path]:
    """Interactive mode to select entry points."""
    print("\n" + "=" * 80)
    print("INTERACTIVE MODE - Select Entry Points")
    print("=" * 80)

    # Find default entry points
    default_entries = find_default_entry_points(project_root)

    print(f"\nProject root: {project_root}")
    print("\nHow would you like to specify entry points?")
    print("1. Use default patterns (*/visualization/app.py, */main.py, *cli.py)")
    print("2. Enter custom paths manually")
    print("3. Choose from found Python files")

    choice = input("\nSelect option (1-3): ").strip()

    if choice == '1':
        if default_entries:
            print(f"\nFound {len(default_entries)} default entry points:")
            for i, ep in enumerate(default_entries, 1):
                print(f"  {i}. {ep.relative_to(project_root)}")

            confirm = input("\nUse these entry points? (y/n): ").strip().lower()
            if confirm == 'y':
                return default_entries
        else:
            print("\nNo default entry points found.")

    if choice == '3':
        # Show available Python files
        gitignore = GitignoreParser(project_root)
        py_files = []

        for root, dirs, files in os.walk(project_root):
            root_path = Path(root)
            # Skip common directories
            dirs[:] = [d for d in dirs if d not in {
                '__pycache__', '.git', '.venv', 'venv', 'env',
                'node_modules', '.tox', '.pytest_cache', '.mypy_cache',
                'build', 'dist', '.egg-info'
            }]
            dirs[:] = [d for d in dirs if not gitignore.is_ignored(root_path / d)]

            for file in sorted(files):
                if file.endswith('.py'):
                    file_path = root_path / file
                    if not gitignore.is_ignored(file_path):
                        py_files.append(file_path)

        if py_files:
            print(f"\nFound {len(py_files)} Python files. Showing first 50:")
            for i, file_path in enumerate(py_files[:50], 1):
                rel_path = file_path.relative_to(project_root)
                print(f"  {i:2d}. {rel_path}")

            if len(py_files) > 50:
                print(f"  ... and {len(py_files) - 50} more files")

            print("\nEnter file numbers separated by commas (e.g., 1,3,5)")
            print("Or press Enter to enter paths manually")

            selection = input("\nYour selection: ").strip()
            if selection:
                try:
                    indices = [int(x.strip()) - 1 for x in selection.split(',')]
                    selected = []
                    for idx in indices:
                        if 0 <= idx < len(py_files):
                            selected.append(py_files[idx])
                    if selected:
                        print(f"\nSelected {len(selected)} entry points:")
                        for ep in selected:
                            print(f"  ✓ {ep.relative_to(project_root)}")
                        return selected
                except ValueError:
                    print("Invalid selection format.")

    # Manual entry mode
    print("\nEnter paths to main files (relative to project root).")
    print("Enter one path per line. Press Enter on empty line when done.")
    print("Example: src/main.py")

    entry_points = []
    while True:
        path_str = input("> ").strip()
        if not path_str:
            break

        # Handle both absolute and relative paths
        if os.path.isabs(path_str):
            file_path = Path(path_str)
        else:
            file_path = project_root / path_str

        if file_path.exists() and file_path.is_file():
            entry_points.append(file_path.resolve())
            print(f"  ✓ Added: {file_path.relative_to(project_root)}")
        else:
            print(f"  ✗ File not found: {path_str}")

    if not entry_points:
        print("\nNo entry points selected. Exiting.")
        sys.exit(1)

    return entry_points


def generate_report(project_root: Path, results: Dict[str, Set[Path]], all_files: Set[Path]):
    """Generate a report of unused files."""
    print("\n" + "=" * 80)
    print("UNUSED FILE ANALYSIS REPORT")
    print("=" * 80)
    print(f"\nProject Root: {project_root}")
    print(f"Total Python files found: {len(all_files)} (excluding gitignored files)")

    # Files used by each entry point
    all_used_files = set()

    for entry_point, used_files in results.items():
        print(f"\n\nEntry Point: {Path(entry_point).relative_to(project_root)}")
        print(f"Files used: {len(used_files)}")
        print("-" * 40)

        # Convert to relative paths for readability
        relative_used = sorted([
            str(f.relative_to(project_root))
            for f in used_files
            if f.is_relative_to(project_root)
        ])

        for file_path in relative_used[:10]:  # Show first 10
            print(f"  ✓ {file_path}")

        if len(relative_used) > 10:
            print(f"  ... and {len(relative_used) - 10} more files")

        all_used_files.update(used_files)

    # Find unused files
    unused_files = all_files - all_used_files

    print("\n" + "=" * 80)
    print(f"UNUSED FILES (not imported by any entry point): {len(unused_files)}")
    print("=" * 80)

    if unused_files:
        # Group by directory for better organization
        by_directory = defaultdict(list)
        for file_path in unused_files:
            if file_path.is_relative_to(project_root):
                rel_path = file_path.relative_to(project_root)
                directory = rel_path.parent
                by_directory[directory].append(rel_path)

        for directory in sorted(by_directory.keys()):
            print(f"\n{directory}/")
            for file_path in sorted(by_directory[directory]):
                print(f"  ✗ {file_path.name}")

        # Ask if user wants to save the list
        print("\n" + "-" * 80)
        save = input("\nSave unused files list to a file? (y/n): ").strip().lower()
        if save == 'y':
            output_file = project_root / 'unused_files.txt'
            with open(output_file, 'w') as f:
                f.write("Unused Python Files\n")
                f.write("=" * 50 + "\n")
                f.write(f"Generated from: {project_root}\n")
                f.write(f"Total unused files: {len(unused_files)}\n\n")

                for file_path in sorted(unused_files):
                    if file_path.is_relative_to(project_root):
                        f.write(f"{file_path.relative_to(project_root)}\n")

            print(f"✓ Saved to: {output_file}")
    else:
        print("\n✓ No unused files found! All Python files are imported.")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total files: {len(all_files)}")
    print(f"Used files: {len(all_used_files)}")
    print(f"Unused files: {len(unused_files)}")
    if all_files:
        print(f"Usage rate: {len(all_used_files) / len(all_files) * 100:.1f}%")


def main():
    parser = argparse.ArgumentParser(
        description="Find unused Python files in your project by tracing imports from entry points."
    )
    parser.add_argument(
        'entry_points',
        nargs='*',
        help='Entry point files (e.g., main.py, app.py). If not specified, interactive mode.'
    )
    parser.add_argument(
        '--root',
        type=Path,
        default=Path.cwd(),
        help='Project root directory (default: current directory)'
    )
    parser.add_argument(
        '-i', '--interactive',
        action='store_true',
        help='Force interactive mode even if entry points are provided'
    )

    args = parser.parse_args()

    project_root = args.root.resolve()

    # Get entry points
    if args.interactive or not args.entry_points:
        entry_points = interactive_select_entry_points(project_root)
    else:
        entry_points = [project_root / ep for ep in args.entry_points]

    print("\nAnalyzing imports...")

    # Analyze the project
    tracer = ImportTracer(project_root)

    if not tracer.all_python_files:
        print("\nNo Python files found in the project (excluding gitignored files).")
        sys.exit(1)

    results = tracer.analyze(entry_points)

    # Generate report
    generate_report(project_root, results, tracer.all_python_files)


if __name__ == '__main__':
    main()
