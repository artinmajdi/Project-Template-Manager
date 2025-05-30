#!/usr/bin/env python3
"""
Script to install type stubs for packages in requirements.txt in the existing .venv environment
"""

import re
import subprocess
import sys
import os
import venv
import shutil
from pathlib import Path
from typing import List, Tuple

# Common packages that might have type stubs available
POTENTIAL_STUB_PACKAGES = [
    "Flask", "Flask-Cors", "Werkzeug", "openpyxl", "xlrd", "seaborn", "pillow",
    "protobuf", "regex", "jinja2", "requests", "tqdm", "colorama", "httpx",
    "tenacity", "pytest", "pytest-cov"
]

def parse_requirements(requirements_path: str) -> List[str]:
    """Parse requirements.txt file and extract package names without version constraints."""
    packages = []
    with open(requirements_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            # Extract package name (remove version specifiers)
            package_name = re.split(r'[<>=~]', line)[0].strip()
            packages.append(package_name)

    return packages

def check_stub_availability(package_name: str) -> bool:
    """Check if type stubs are available for a package on PyPI."""
    stub_package = f"types-{package_name}"
    try:
        import urllib.request
        import urllib.error
        import json

        url = f"https://pypi.org/pypi/{stub_package}/json"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})

        with urllib.request.urlopen(req, timeout=5) as response:
            return response.getcode() == 200
    except urllib.error.HTTPError as e:
        if e.code == 404:  # Package not found
            return False
        else:
            print(f"HTTP error checking {stub_package}: {e.code}")
            return False
    except Exception as e:
        print(f"Error checking {stub_package}: {e}")
        return False

def generate_stubs_list(packages: List[str]) -> List[str]:
    """Generate a list of type stub packages for the given packages."""
    stub_packages = []
    print("Checking which packages have type stubs available...")

    # First check packages that are in our potential list
    for package in packages:
        if package in POTENTIAL_STUB_PACKAGES:
            if check_stub_availability(package):
                stub_packages.append(f"types-{package}")
                print(f"  ✓ Found type stubs for {package}")
            else:
                print(f"  ✗ No type stubs available for {package}")

    # Then check any remaining packages not in our potential list
    # but only if they're in the requirements.txt
    remaining_packages = [p for p in packages if p not in POTENTIAL_STUB_PACKAGES]
    if remaining_packages:
        print("\nChecking additional packages...")
        for package in remaining_packages:
            if check_stub_availability(package):
                stub_packages.append(f"types-{package}")
                print(f"  ✓ Found type stubs for {package}")

    return stub_packages

def setup_venv(venv_path: Path) -> Tuple[bool, str]:
    """Use the existing virtual environment for installing type stubs."""
    try:
        # Check if venv exists
        if not venv_path.exists():
            print(f"Error: Virtual environment not found at {venv_path}")
            print("Please create the .venv environment first.")
            return False, ""

        print(f"Using existing virtual environment at {venv_path}")
        pip_path = get_venv_pip_path(venv_path)

        return True, pip_path
    except Exception as e:
        print(f"Error setting up virtual environment: {e}")
        return False, ""

def get_venv_pip_path(venv_path: Path) -> str:
    """Get the path to pip in the virtual environment."""
    if sys.platform == "win32":
        return str(venv_path / "Scripts" / "pip.exe")
    else:
        return str(venv_path / "bin" / "pip")

def install_stubs_in_venv(pip_path: str, stubs_file: Path) -> bool:
    """Install type stubs in the virtual environment."""
    try:
        print(f"Installing type stubs using {pip_path}...")
        result = subprocess.run(
            [pip_path, "install", "-r", str(stubs_file)],
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            print("Successfully installed type stubs in virtual environment!")
            return True
        else:
            print("Failed to install type stubs in virtual environment.")
            print("Error:")
            print(result.stderr)
            return False
    except Exception as e:
        print(f"Error installing type stubs: {e}")
        return False

def main():
    """Main function to parse requirements and install stubs in the existing .venv environment."""
    # Get project root path
    project_root = Path(__file__).parent.parent  # Adjusted to account for being in scripts/ directory
    requirements_path = project_root / "requirements.txt"

    if not requirements_path.exists():
        print(f"Error: {requirements_path} not found")
        sys.exit(1)

    # Parse command line arguments
    dry_run = "--dry-run" in sys.argv

    # Parse requirements and get packages
    print(f"Parsing {requirements_path}...")
    packages = parse_requirements(str(requirements_path))
    print(f"Found {len(packages)} packages")

    # Generate list of stub packages
    stub_packages = generate_stubs_list(packages)
    print(f"Found {len(stub_packages)} packages with available type stubs")

    if not stub_packages:
        print("No type stubs found for the packages in requirements.txt")
        return

    # Print the list of stub packages
    print("\nType stubs to install:")
    for stub in stub_packages:
        print(f"  {stub}")

    # Install stubs
    if not dry_run:
        # Create a requirements file for stubs
        stubs_file = project_root / "setup_config/type_stubs_requirements.txt"
        with open(stubs_file, "w") as f:
            f.write("\n".join(stub_packages))

        print(f"Created {stubs_file} with {len(stub_packages)} type stub packages")

        # Use the existing .venv environment
        venv_path = project_root / ".venv"
        success, pip_path = setup_venv(venv_path)

        if success:
            # Install stubs in virtual environment
            install_stubs_in_venv(pip_path, stubs_file)

            print("\nType stubs have been installed in your existing .venv environment.")
            print(f"Your IDE should now have access to these type stubs when using the Python interpreter from:")
            print(f"   Path: {venv_path}/bin/python")
        else:
            print("Failed to set up virtual environment for type stubs.")
    else:
        print("\nDry run mode. Not installing type stubs.")

if __name__ == "__main__":
    main()
