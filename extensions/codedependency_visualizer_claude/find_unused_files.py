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
import json


# TODO: make it ignore the gitignore files/folders
class GitignoreParser:
    """Simple gitignore parser to filter out ignored files."""

    def __init__(self, project_root: Path, debug: bool = False):
        """
        Initialize the GitignoreParser.

        :param project_root: The root directory of the project
        :param debug: Whether to print debug information
        """
        self.project_root = project_root
        self.patterns = []
        self.debug = debug
        # Add common patterns that should always be ignored
        self._add_default_patterns()
        self._load_gitignore()

    def _add_default_patterns(self):
        """Add common patterns that should always be ignored."""
        default_patterns = [
            '__pycache__/',
            '*.pyc',
            '*.pyo',
            '*.pyd',
            '.Python',
            'env/',
            'venv/',
            '.venv/',
            '.env',
            '.git/',
            '.pytest_cache/',
            '.mypy_cache/',
            '.tox/',
            'build/',
            'dist/',
            '*.egg-info/',
            'node_modules/',
        ]

        for pattern in default_patterns:
            regex_pattern = self._gitignore_to_regex(pattern)
            self.patterns.append(regex_pattern)
            if self.debug:
                print(f"Added default pattern: {pattern} -> {regex_pattern.pattern}", file=sys.stderr)

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
                    if self.debug:
                        print(f"Added gitignore pattern: {pattern} -> {regex_pattern.pattern}", file=sys.stderr)

        except Exception as e:
            print(f"Warning: Could not parse .gitignore: {e}", file=sys.stderr)

    def _gitignore_to_regex(self, pattern: str) -> re.Pattern:
        """Convert gitignore pattern to regex."""
        # Handle directory patterns first
        is_directory = pattern.endswith('/')
        if is_directory:
            pattern = pattern[:-1]

        # Escape special regex characters except * and ?
        escaped = re.escape(pattern)
        escaped = escaped.replace(r'\*\*', '🌟🌟')  # Temporary placeholder for **
        escaped = escaped.replace(r'\*', '🌟')      # Temporary placeholder for *
        escaped = escaped.replace(r'\?', '❓')      # Temporary placeholder for ?

        # Replace placeholders with proper regex
        escaped = escaped.replace('🌟🌟', '.*')     # ** matches everything including /
        escaped = escaped.replace('🌟', '[^/]*')   # * matches anything except /
        escaped = escaped.replace('❓', '.')        # ? matches single character

        # Handle different pattern types
        if pattern.startswith('/'):
            # Absolute pattern from root
            regex_pattern = '^' + escaped[1:] + ('(/.*)?$' if is_directory else '$')
        else:
            # Pattern can match at any level
            if is_directory:
                regex_pattern = '(^|.*/)' + escaped + '(/.*)?$'
            else:
                regex_pattern = '(^|.*/)' + escaped + '$'

        return re.compile(regex_pattern)

    def is_ignored(self, file_path: Path) -> bool:
        """Check if a file should be ignored."""
        try:
            relative_path = file_path.relative_to(self.project_root)
            path_str = str(relative_path.as_posix())

            # Check if the file itself matches any pattern
            for pattern in self.patterns:
                if pattern.match(path_str):
                    return True

            # Check if any parent directory matches a directory pattern
            current_path = relative_path
            while current_path != Path('.'):
                current_str = str(current_path.as_posix())
                for pattern in self.patterns:
                    if pattern.match(current_str):
                        return True
                current_path = current_path.parent

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
        def should_explore_directory(dir_path: Path) -> bool:
            """Check if we should explore a directory (not gitignored)."""
            return not self.gitignore.is_ignored(dir_path)

        for root, dirs, files in os.walk(self.project_root):
            root_path = Path(root)

            # Filter out directories that should be ignored
            dirs[:] = [d for d in dirs if should_explore_directory(root_path / d)]

            # Process Python files in current directory
            for file in files:
                if file.endswith('.py'):
                    file_path = root_path / file
                    # Only add if not gitignored
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
                    # Handle the module part of "from module import ..."
                    # This module needs to be resolved to its file.
                    module_source_to_register = None
                    if node.level == 0:  # Absolute import: from X.Y import Z
                        if node.module:
                            module_source_to_register = node.module  # X.Y
                    else:  # Relative import: from .X import Y or ..X import Y
                        current_pkg_path_parts = []
                        # Determine current package path relative to project_root
                        if file_path.is_relative_to(self.project_root):
                            current_pkg_path_parts = list(file_path.parent.relative_to(self.project_root).parts)

                        # Calculate effective base parts for the import
                        # e.g. current is proj/src/a/b/c.py -> current_pkg_path_parts = (src,a,b)
                        # level 1 (.X) -> base is (src,a,b)
                        # level 2 (..X) -> base is (src,a)
                        if node.level > 0 and (node.level <= len(current_pkg_path_parts) + 1 if current_pkg_path_parts else node.level ==1) :
                            if node.level == 1:
                                effective_base_parts = current_pkg_path_parts
                            else: # node.level > 1
                                effective_base_parts = current_pkg_path_parts[:-(node.level - 1)]

                            base_package_str = '.'.join(effective_base_parts)
                            if node.module:  # from .sibling_module import ...
                                module_source_to_register = f"{base_package_str}.{node.module}"
                            else:  # from . import name1, name2 ...
                                # Each name in node.names is a module relative to base_package_str
                                for alias in node.names:
                                    imports.append(f"{base_package_str}.{alias.name}")
                                # module_source_to_register remains None, items handled individually
                        # else: relative import goes beyond project root or file not in project

                    if module_source_to_register:
                        imports.append(module_source_to_register)

        except Exception as e:
            print(f"Warning: Could not parse {file_path}: {e}", file=sys.stderr)

        return imports

    def _resolve_import_to_file(self, import_name: str, current_file: Path) -> Set[Path]:
        """Resolve an import name to actual file paths, considering project structure."""
        resolved_files = set()
        parts = import_name.split('.')

        # Define potential Python source roots for this project
        search_roots = []
        src_dir = self.project_root / "src"
        if src_dir.is_dir():
            search_roots.append(src_dir)
        search_roots.append(self.project_root) # Fallback or for projects without src layout

        for s_root in search_roots:
            module_path_candidate = s_root.joinpath(*parts)

            # Check for .py file (e.g., s_root/pkg/module.py)
            py_file = module_path_candidate.with_suffix('.py')
            if py_file.exists() and py_file.is_file():
                if py_file.is_relative_to(self.project_root) and not self.gitignore.is_ignored(py_file):
                    resolved_files.add(py_file.resolve())

            # Check for package (directory with __init__.py) (e.g., s_root/pkg/module/__init__.py)
            init_file = module_path_candidate / '__init__.py'
            if init_file.exists() and init_file.is_file():
                if init_file.is_relative_to(self.project_root) and not self.gitignore.is_ignored(init_file):
                    resolved_files.add(init_file.resolve())

        return resolved_files

    def build_dependency_graph(self, entry_point: Path, max_depth: int = 10) -> Tuple[Set[Path], Dict[Path, Set[Path]]]:
        """
        Trace all imports starting from an entry point and build a dependency graph.

        Args:
            entry_point: The starting point for analysis
            max_depth: Maximum depth to traverse (1 = only entry point, 2 = entry + direct deps, etc.)

        Returns:
            A tuple containing:
            - A set of all files that are part of the dependency chain.
            - A dictionary representing the dependency graph (file -> set of direct imports).
        """
        all_dependent_files: Set[Path] = set()
        dependency_graph: Dict[Path, Set[Path]] = defaultdict(set)

        # Queue now stores tuples of (file_path, depth_level)
        queue: List[Tuple[Path, int]] = [(entry_point.resolve(), 0)]
        processed_for_imports: Set[Path] = set() # Files whose imports have been parsed
        file_depths: Dict[Path, int] = {entry_point.resolve(): 0}  # Track depth of each file

        all_dependent_files.add(entry_point.resolve())

        head = 0
        while head < len(queue):
            current_file, current_depth = queue[head]
            head += 1

            if current_file in processed_for_imports:
                continue
            processed_for_imports.add(current_file)

            # Only process imports if we haven't reached max depth
            if current_depth >= max_depth:
                continue

            # Get imports from this file
            imports = self._parse_imports(current_file)
            direct_deps_for_current_file: Set[Path] = set()

            # Resolve imports to files
            for import_name in imports:
                resolved_files = self._resolve_import_to_file(import_name, current_file)
                for resolved_file in resolved_files:
                    if resolved_file in self.all_python_files: # Ensure it's a project file
                        direct_deps_for_current_file.add(resolved_file)
                        if resolved_file not in all_dependent_files:
                            all_dependent_files.add(resolved_file)
                            new_depth = current_depth + 1
                            file_depths[resolved_file] = new_depth
                            # Only add to queue if within depth limit
                            if new_depth < max_depth:
                                queue.append((resolved_file, new_depth))

            if direct_deps_for_current_file:
                dependency_graph[current_file.resolve()] = direct_deps_for_current_file

        return all_dependent_files, dependency_graph

    def trace_imports(self, entry_point: Path, max_depth: int = 10) -> Set[Path]:
        """Trace all imports starting from an entry point and return a flat set of used files."""
        all_dependent_files, _ = self.build_dependency_graph(entry_point, max_depth)
        return all_dependent_files

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

                # Skip gitignored directories
                dirs[:] = [d for d in dirs if not gitignore.is_ignored(root_path / d)]

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


def get_all_python_files_for_selection(project_root: Path) -> List[Path]:
    """Get all Python files for interactive selection with autocomplete-like functionality."""
    gitignore = GitignoreParser(project_root)
    py_files = []

    for root, dirs, files in os.walk(project_root):
        root_path = Path(root)
        # Skip gitignored directories
        dirs[:] = [d for d in dirs if not gitignore.is_ignored(root_path / d)]

        for file in sorted(files):
            if file.endswith('.py'):
                file_path = root_path / file
                if not gitignore.is_ignored(file_path):
                    py_files.append(file_path)

    return sorted(py_files)


def select_single_entry_point(project_root: Path) -> Path:
    """Select a single entry point for dependency analysis."""
    print("\n" + "=" * 80)
    print("SELECT MAIN FILE FOR DEPENDENCY ANALYSIS")
    print("=" * 80)

    # Find default entry points
    default_entries = find_default_entry_points(project_root)

    print(f"\nProject root: {project_root}")
    print("\nHow would you like to specify the main file?")
    print("1. Use default patterns (*/visualization/app.py, */main.py, *cli.py)")
    print("2. Enter custom path manually")
    print("3. Choose from found Python files")

    choice = input("\nSelect option (1-3): ").strip()

    if choice == '1':
        if default_entries:
            print(f"\nFound {len(default_entries)} default entry points:")
            for i, ep in enumerate(default_entries, 1):
                print(f"  {i}. {ep.relative_to(project_root)}")

            while True:
                try:
                    selection = input(f"\nSelect file (1-{len(default_entries)}): ").strip()
                    idx = int(selection) - 1
                    if 0 <= idx < len(default_entries):
                        return default_entries[idx]
                    else:
                        print(f"Please enter a number between 1 and {len(default_entries)}")
                except ValueError:
                    print("Please enter a valid number")
        else:
            print("\nNo default entry points found.")

    if choice == '3':
        py_files = get_all_python_files_for_selection(project_root)

        if py_files:
            print(f"\nFound {len(py_files)} Python files. Showing first 50:")
            for i, file_path in enumerate(py_files[:50], 1):
                rel_path = file_path.relative_to(project_root)
                print(f"  {i:2d}. {rel_path}")

            if len(py_files) > 50:
                print(f"  ... and {len(py_files) - 50} more files")

            while True:
                try:
                    selection = input(f"\nSelect file (1-{min(50, len(py_files))}): ").strip()
                    idx = int(selection) - 1
                    if 0 <= idx < min(50, len(py_files)):
                        return py_files[idx]
                    else:
                        print(f"Please enter a number between 1 and {min(50, len(py_files))}")
                except ValueError:
                    print("Please enter a valid number")

    # Manual entry mode
    print("\nEnter path to main file (relative to project root).")
    print("Example: src/main.py")

    while True:
        path_str = input("> ").strip()
        if not path_str:
            continue

        # Handle both absolute and relative paths
        if os.path.isabs(path_str):
            file_path = Path(path_str)
        else:
            file_path = project_root / path_str

        if file_path.exists() and file_path.is_file():
            return file_path.resolve()
        else:
            print(f"  ✗ File not found: {path_str}")
            print("Please try again or press Ctrl+C to exit")


def interactive_select_entry_points_for_unused_files(project_root: Path) -> List[Path]:
    """Interactive mode to select entry points for unused file analysis."""
    print("\n" + "=" * 80)
    print("SELECT ENTRY POINTS FOR UNUSED FILE ANALYSIS")
    print("=" * 80)

    # Find default entry points
    default_entries = find_default_entry_points(project_root)

    print(f"\nProject root: {project_root}")
    print("\nHow would you like to specify entry points?")
    print("1. Use default patterns (*/visualization/app.py, */main.py, *cli.py)")
    print("2. Enter custom paths manually")
    print("3. Choose from found Python files")

    choice = input("\nSelect option (1-3): ").strip()

    entry_points = []

    if choice == '1':
        if default_entries:
            print(f"\nFound {len(default_entries)} default entry points:")
            for i, ep in enumerate(default_entries, 1):
                print(f"  {i}. {ep.relative_to(project_root)}")

            confirm = input("\nUse these entry points? (y/n): ").strip().lower()
            if confirm == 'y':
                entry_points = default_entries[:]
        else:
            print("\nNo default entry points found.")

    elif choice == '3':
        py_files = get_all_python_files_for_selection(project_root)

        if py_files:
            print(f"\nFound {len(py_files)} Python files. Showing first 50:")
            for i, file_path in enumerate(py_files[:50], 1):
                rel_path = file_path.relative_to(project_root)
                print(f"  {i:2d}. {rel_path}")

            if len(py_files) > 50:
                print(f"  ... and {len(py_files) - 50} more files")

            print("\nEnter file numbers separated by commas (e.g., 1,3,5)")
            print("Or press Enter to skip")

            selection = input("\nYour selection: ").strip()
            if selection:
                try:
                    indices = [int(x.strip()) - 1 for x in selection.split(',')]
                    for idx in indices:
                        if 0 <= idx < len(py_files):
                            entry_points.append(py_files[idx])
                    if entry_points:
                        print(f"\nSelected {len(entry_points)} entry points:")
                        for ep in entry_points:
                            print(f"  ✓ {ep.relative_to(project_root)}")
                except ValueError:
                    print("Invalid selection format.")

    # Ask if user wants to add more entry points
    print(f"\nCurrent entry points: {len(entry_points)}")
    if entry_points:
        for ep in entry_points:
            print(f"  ✓ {ep.relative_to(project_root)}")

    add_more = input("\nWould you like to add more main files? (y/n): ").strip().lower()

    if add_more == 'y':
        print("\nEnter paths to additional main files (relative to project root).")
        print("Enter one path per line. Press Enter on empty line when done.")
        print("Example: src/main.py")

        # Get all Python files for autocomplete-like suggestions
        py_files = get_all_python_files_for_selection(project_root)
        py_file_paths = [str(f.relative_to(project_root)) for f in py_files]

        while True:
            path_str = input("> ").strip()
            if not path_str:
                break

            # Simple autocomplete: show suggestions if partial match
            if len(path_str) > 2:
                matches = [p for p in py_file_paths if path_str.lower() in p.lower()]
                if matches and len(matches) <= 10:
                    print("  Suggestions:")
                    for match in matches:
                        print(f"    {match}")

            # Handle both absolute and relative paths
            if os.path.isabs(path_str):
                file_path = Path(path_str)
            else:
                file_path = project_root / path_str

            if file_path.exists() and file_path.is_file():
                if file_path.resolve() not in entry_points:
                    entry_points.append(file_path.resolve())
                    print(f"  ✓ Added: {file_path.relative_to(project_root)}")
                else:
                    print(f"  ⚠ Already in list: {file_path.relative_to(project_root)}")
            else:
                print(f"  ✗ File not found: {path_str}")

    if not entry_points:
        print("\nNo entry points selected. Using default patterns.")
        entry_points = default_entries if default_entries else []

    return entry_points


def interactive_select_entry_points(project_root: Path) -> List[Path]:
    """Interactive mode to select entry points."""
    # This function is kept for backwards compatibility but simplified
    # The main logic is now in the new functions above
    return interactive_select_entry_points_for_unused_files(project_root)


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


def _generate_dependency_tree_lines_recursive(
    file_path: Path,
    dependency_graph: Dict[Path, Set[Path]],
    project_root: Path,
    prefix: str = "",
    is_last_child: bool = True,
    visited_in_path: Optional[Set[Path]] = None
) -> List[str]:
    """Recursively generates lines for the dependency tree."""
    if visited_in_path is None:
        visited_in_path = set()

    lines = []
    # Display path relative to project root
    display_path = file_path.relative_to(project_root) if file_path.is_relative_to(project_root) else file_path

    connector = "└── " if is_last_child else "├── "
    lines.append(f"{prefix}{connector}{display_path}")

    # Cycle detection for the current path
    if file_path in visited_in_path:
        lines.append(f"{prefix}{'    ' if is_last_child else '│   '}└─ ... (circular dependency)")
        return lines

    new_visited_in_path = visited_in_path.copy()
    new_visited_in_path.add(file_path)

    direct_dependencies = sorted(
        list(dependency_graph.get(file_path, set())),
        key=lambda p: str(p.relative_to(project_root) if p.is_relative_to(project_root) else p)
    )

    for i, dep_file in enumerate(direct_dependencies):
        new_prefix = prefix + ("    " if is_last_child else "│   ")
        lines.extend(
            _generate_dependency_tree_lines_recursive(
                dep_file,
                dependency_graph,
                project_root,
                new_prefix,
                is_last_child=(i == len(direct_dependencies) - 1),
                visited_in_path=new_visited_in_path
            )
        )
    return lines


def _generate_dot_output(
    entry_point: Path,
    all_dependent_files: Set[Path],
    dependency_graph: Dict[Path, Set[Path]],
    project_root: Path
) -> str:
    """Generates a Graphviz DOT language string for the dependency graph."""
    dot_lines = ["digraph Dependencies {", "    rankdir=LR; // Left to right layout"]

    # Define a helper to create safe IDs for DOT
    def to_dot_id(p: Path) -> str:
        rel_path_str = str(p.relative_to(project_root) if p.is_relative_to(project_root) else p)
        # Replace characters not suitable for DOT IDs
        return re.sub(r'[^a-zA-Z0-9_]', '_', rel_path_str)

    # Define nodes
    dot_lines.append("\n    // Node definitions")
    sorted_files = sorted(list(all_dependent_files), key=lambda x: str(x))

    for file_path in sorted_files:
        node_id = to_dot_id(file_path)
        label = str(file_path.relative_to(project_root) if file_path.is_relative_to(project_root) else file_path)
        attrs = f'label="{label}"'
        if file_path.resolve() == entry_point.resolve():
            attrs += ', style=filled, fillcolor=lightblue'
        dot_lines.append(f'    {node_id} [{attrs}];')

    # Define edges
    dot_lines.append("\n    // Edge definitions")
    # Sort for consistent output
    sorted_graph_keys = sorted(list(dependency_graph.keys()), key=lambda x: str(x))

    for source_file_abs in sorted_graph_keys:
        source_id = to_dot_id(source_file_abs)
        # Sort dependencies for consistent output
        for dep_file_abs in sorted(list(dependency_graph[source_file_abs]), key=lambda x: str(x)):
            dep_id = to_dot_id(dep_file_abs)
            dot_lines.append(f'    {source_id} -> {dep_id};')

    dot_lines.append("}")
    return "\n".join(dot_lines)

def generate_dependency_report(project_root: Path, entry_point: Path, all_dependent_files: Set[Path], dependency_graph: Dict[Path, Set[Path]]):
    """Generate a report showing dependencies for a single entry point."""
    print("\n" + "=" * 80)
    print("DEPENDENCY ANALYSIS REPORT")
    print("=" * 80)
    print(f"\nProject Root: {project_root}")
    print(f"Main File: {entry_point.relative_to(project_root)}")
    print(f"Total unique dependencies (including main file): {len(all_dependent_files)}")

    print("\n" + "=" * 80)
    print("DEPENDENCY TREE")
    print("=" * 80)

    tree_output_lines = [str(entry_point.relative_to(project_root))] # Root of the tree

    direct_deps_of_entry = sorted(
        list(dependency_graph.get(entry_point.resolve(), set())),
        key=lambda p: str(p.relative_to(project_root) if p.is_relative_to(project_root) else p)
    )

    for i, dep_file in enumerate(direct_deps_of_entry):
        tree_output_lines.extend(
            _generate_dependency_tree_lines_recursive(
                dep_file,
                dependency_graph,
                project_root,
                prefix="", # Initial prefix for the first level children
                is_last_child=(i == len(direct_deps_of_entry) - 1),
                visited_in_path={entry_point.resolve()} # Start with entry_point in visited_in_path
            )
        )

    for line in tree_output_lines:
        print(line)

    # Ask if user wants to save the list
    print("\n" + "-" * 80)
    save = input("\nSave dependency list to a file? (y/n): ").strip().lower()
    if save == 'y':
        output_file_dot = project_root / f'dependencies_{entry_point.stem}.dot'
        dot_content = _generate_dot_output(entry_point, all_dependent_files, dependency_graph, project_root)
        with open(output_file_dot, 'w') as f:
            f.write(dot_content)
        print(f"✓ Saved DOT graph to: {output_file_dot}")
        print("  You can visualize this file using Graphviz (e.g., `dot -Tpng {output_file_dot} -o graph.png`)")

    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Main file: {entry_point.relative_to(project_root)}")
    print(f"Total unique dependencies: {len(all_dependent_files)}")


def test_gitignore_parsing(project_root: Path):
    """Test gitignore parsing with some sample paths."""
    print("\n" + "=" * 80)
    print("TESTING GITIGNORE PARSING")
    print("=" * 80)

    gitignore = GitignoreParser(project_root, debug=True)

    # Test some common paths
    test_paths = [
        "__pycache__/test.pyc",
        "src/__pycache__/module.pyc",
        ".git/config",
        "venv/lib/python3.9/site-packages/test.py",
        ".pytest_cache/test.py",
        "build/lib/test.py",
        "dist/test.py",
        "src/main.py",
        "tests/test_example.py",
    ]

    print("\nTesting gitignore patterns on sample paths:")
    for test_path in test_paths:
        full_path = project_root / test_path
        is_ignored = gitignore.is_ignored(full_path)
        status = "IGNORED" if is_ignored else "INCLUDED"
        print(f"  {status:8} {test_path}")


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
    parser.add_argument(
        '--test-gitignore',
        action='store_true',
        help='Test gitignore parsing and exit'
    )
    parser.add_argument(
        '--json-output',
        action='store_true',
        help='Output dependency graph as JSON for VS Code extension'
    )
    parser.add_argument(
        '--max-depth',
        type=int,
        default=10,
        help='Maximum depth for dependency analysis (default: 10)'
    )

    args = parser.parse_args()

    project_root = args.root.resolve()

    # Test gitignore parsing if requested
    if args.test_gitignore:
        test_gitignore_parsing(project_root)
        return

    # JSON output mode for VS Code extension
    if args.json_output:
        if not args.entry_points:
            print("Error: Entry point required for JSON output mode", file=sys.stderr)
            sys.exit(1)

        entry_point = project_root / args.entry_points[0]
        if not entry_point.exists():
            print(f"Error: Entry point {entry_point} does not exist", file=sys.stderr)
            sys.exit(1)

        tracer = ImportTracer(project_root)
        all_dependent_files, dependency_graph = tracer.build_dependency_graph(entry_point, args.max_depth)

        # Convert to JSON format expected by VS Code extension
        nodes = []
        edges = []

        # Create nodes
        for file_path in all_dependent_files:
            rel_path = file_path.relative_to(project_root)
            file_type = 'python'  # Since we're analyzing Python files

            nodes.append({
                'id': str(rel_path),
                'label': file_path.name,
                'fullPath': str(file_path),
                'type': file_type
            })

        # Create edges
        for source_file, target_files in dependency_graph.items():
            source_rel = source_file.relative_to(project_root)
            for target_file in target_files:
                target_rel = target_file.relative_to(project_root)
                edges.append({
                    'source': str(source_rel),
                    'target': str(target_rel)
                })

        result = {
            'nodes': nodes,
            'edges': edges,
            'entryPoint': str(entry_point.relative_to(project_root)),
            'maxDepth': args.max_depth
        }

        print(json.dumps(result, indent=2))
        return

    # Mode selection
    print("\n" + "=" * 80)
    print("PYTHON FILE ANALYSIS TOOL")
    print("=" * 80)
    print("\nSelect analysis mode:")
    print("1. Find dependencies (show all files imported by a single main file)")
    print("2. Find unused files (show files not used by any main files)")

    while True:
        try:
            mode = input("\nSelect mode (1-2): ").strip()
            if mode in ['1', '2']:
                break
            else:
                print("Please enter 1 or 2")
        except KeyboardInterrupt:
            print("\nExiting...")
            sys.exit(0)

    # Analyze the project
    tracer = ImportTracer(project_root)

    if not tracer.all_python_files:
        print("\nNo Python files found in the project (excluding gitignored files).")
        sys.exit(1)

    if mode == '1':
        # Find dependencies mode
        if args.interactive or not args.entry_points:
            entry_point = select_single_entry_point(project_root)
        else:
            entry_point = project_root / args.entry_points[0]

        print(f"\nAnalyzing dependencies for: {entry_point.relative_to(project_root)}")
        all_dependent_files, dependency_graph = tracer.build_dependency_graph(entry_point, args.max_depth)

        # Generate dependency report
        generate_dependency_report(project_root, entry_point, all_dependent_files, dependency_graph)

    else:
        # Find unused files mode
        if args.interactive or not args.entry_points:
            entry_points = interactive_select_entry_points_for_unused_files(project_root)
        else:
            entry_points = [project_root / ep for ep in args.entry_points]

        print("\nAnalyzing imports...")
        results = tracer.analyze(entry_points)

        # Generate unused files report
        generate_report(project_root, results, tracer.all_python_files)


if __name__ == '__main__':
    main()
