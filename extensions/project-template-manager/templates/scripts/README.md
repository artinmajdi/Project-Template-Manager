# Publishing Scripts

This directory contains scripts for managing releases and publishing Python packages.

## Setup for Publishing

### Environment Variables

The publishing scripts can use environment variables for authentication. You can set these in your shell profile or before running the scripts:

```bash
# For PyPI
export PYPI_USERNAME="your_pypi_username"
export PYPI_PASSWORD="your_pypi_password"

# For TestPyPI
export TESTPYPI_USERNAME="your_testpypi_username"
export TESTPYPI_PASSWORD="your_testpypi_password"

# For GitHub Packages
export GITHUB_USERNAME="your_github_username"
export GH_USERNAME="your_github_username"  # Alternative
export GITHUB_TOKEN="your_github_token"
export GH_TOKEN="your_github_token"  # Alternative
```

### Using .pypirc

Alternatively, you can create a `.pypirc` file in the project root with your credentials:

1. Copy the template file:
   ```bash
   cp .pypirc.template .pypirc
   ```

2. Edit the `.pypirc` file with your credentials:
   ```ini
   [distutils]
   index-servers =
       pypi
       testpypi
       github

   [pypi]
   username = your_pypi_username
   password = your_pypi_password

   [testpypi]
   repository = https://test.pypi.org/legacy/
   username = your_testpypi_username
   password = your_testpypi_password

   [github]
   repository = https://github.com/your_username/your_repo/packages/pypi
   username = your_github_username
   password = your_github_token
   ```

3. Ensure the file has restricted permissions:
   ```bash
   chmod 600 .pypirc
   ```

## Publishing Scripts

### publish_to_pypi.sh

This script builds and publishes the Python package to PyPI, TestPyPI, or GitHub Packages.

Usage:
```bash
./scripts/publish_to_pypi.sh [--test | --github]
```

Options:
- No option: Publish to PyPI
- `--test`: Publish to TestPyPI
- `--github`: Publish to GitHub Packages

### release_manager.py

This script manages version updates and creates GitHub releases.

Usage:
```bash
python scripts/release_manager.py [--major | --minor | --patch]
```

Options:
- `--major`: Increment major version (X.0.0)
- `--minor`: Increment minor version (0.X.0)
- `--patch`: Increment patch version (0.0.X)
