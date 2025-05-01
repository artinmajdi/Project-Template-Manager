#!/usr/bin/env python3
"""
Script to build and publish the wound_analysis package to PyPI or GitHub Packages.
This script handles cleaning previous builds, building new distribution files,
and uploading them to the selected repository.

Usage:
    python publish_to_pypi.py [--test | --github]

Options:
    --test: Upload to TestPyPI instead of PyPI
    --github: Upload to GitHub Packages
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

def run_command(command, description=None):
    """Run a shell command and print its output."""
    if description:
        print(f"\n{description}...")

    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)

    print(result.stdout)
    return result.stdout

def clean_build_dirs(project_root):
    """Clean up previous build artifacts."""
    dirs_to_clean = [
        project_root / "dist",
        project_root / "build",
        project_root / "wound_analysis.egg-info"
    ]

    for directory in dirs_to_clean:
        if directory.exists():
            print(f"Removing {directory}")
            shutil.rmtree(directory)

def build_package(project_root):
    """Build the distribution packages."""
    os.chdir(project_root)
    run_command("python -m pip install --upgrade pip build twine", "Upgrading pip, build, and twine")
    run_command("python -m build", "Building distribution packages")

def upload_package(repository="pypi"):
    """Upload the distribution packages to the specified repository."""
    # Use credentials from .pypirc file
    if repository == "testpypi":
        run_command(
            "python -m twine upload --repository testpypi dist/*",
            "Uploading to TestPyPI"
        )
        print("\nPackage uploaded to TestPyPI!")
        print("You can install it with:")
        print("pip install --index-url https://test.pypi.org/simple/project_src")
    elif repository == "github":
        run_command(
            "python -m twine upload --repository github dist/*",
            "Uploading to GitHub Packages"
        )
        print("\nPackage uploaded to GitHub Packages!")
        print("You can install it with:")
        print("pip install --index-url https://github.com/artinmajdi/wound_EHR_analyzer_private/packages/pypi/ project_src")
    else:  # pypi
        run_command("python -m twine upload --repository pypi dist/*", "Uploading to PyPI")
        print("\nPackage uploaded to PyPI!")
        print("You can install it with:")
        print("pip install project_src")

def update_version(project_root):
    """Interactive prompt to update version numbers in setup.py and pyproject.toml."""
    # Read current version from setup.py
    setup_py_path = project_root / "setup.py"
    with open(setup_py_path, 'r') as f:
        setup_content = f.read()

    # Extract current version
    import re
    version_match = re.search(r'version="([^"]+)"', setup_content)
    current_version = version_match.group(1) if version_match else "unknown"

    print(f"\nCurrent version: {current_version}")
    new_version = input("Enter new version (leave blank to keep current): ").strip()

    if new_version and new_version != current_version:
        # Update setup.py
        updated_setup = re.sub(
            r'version="[^"]+"',
            f'version="{new_version}"',
            setup_content
        )
        with open(setup_py_path, 'w') as f:
            f.write(updated_setup)

        # Update pyproject.toml if it exists
        pyproject_path = project_root / "pyproject.toml"
        if pyproject_path.exists():
            with open(pyproject_path, 'r') as f:
                pyproject_content = f.read()

            updated_pyproject = re.sub(
                r'version\s*=\s*"[^"]+"',
                f'version     = "{new_version}"',
                pyproject_content
            )
            with open(pyproject_path, 'w') as f:
                f.write(updated_pyproject)

        print(f"Version updated to {new_version}")
        return new_version

    return current_version

def main():
    """Main function to build and publish the package."""
    project_root = Path(__file__).parent.parent.absolute()

    # Determine target repository
    repository = "pypi"  # default
    if "--test" in sys.argv:
        repository = "testpypi"
    elif "--github" in sys.argv:
        repository = "github"

    print("=" * 80)
    print(f"Publishing Script for project_src to {repository.upper()}")
    print("=" * 80)

    # Update version if needed
    version = update_version(project_root)

    # Confirm before proceeding
    target_names = {"pypi": "PyPI", "testpypi": "TestPyPI", "github": "GitHub Packages"}
    target = target_names.get(repository, repository.upper())
    confirm = input(f"\nReady to build version {version} and publish to {target}? (y/n): ").lower()

    if confirm != 'y':
        print("Aborted.")
        return

    # Clean previous builds
    clean_build_dirs(project_root)

    # Build package
    build_package(project_root)

    # Upload to repository
    upload_package(repository=repository)

    print("\nProcess completed successfully!")

if __name__ == "__main__":
    main()
