#!/bin/bash
# Script to build and publish the project_src package to PyPI or GitHub Packages

set -e  # Exit immediately if a command exits with a non-zero status

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Display banner
echo "============================================================"
echo "Publishing Script for project_src"
echo "============================================================"

# Ask user where to publish if not specified as argument
if [[ -z "$1" ]]; then
    echo "Where would you like to publish?"
    echo "1) PyPI (default)"
    echo "2) TestPyPI"
    echo "3) GitHub Packages"
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        2) PUBLISH_TARGET="--test" ;;
        3) PUBLISH_TARGET="--github" ;;
        *) PUBLISH_TARGET="" ;; # Default to PyPI
    esac
else
    PUBLISH_TARGET="$1"
fi

# Check which repository we're publishing to
if [[ "$PUBLISH_TARGET" == "--test" ]]; then
    REPO="testpypi"
    REPO_NAME="TestPyPI"
    INSTALL_CMD="pip install --index-url https://test.pypi.org/simple/project_src"
    TWINE_ARGS="--repository testpypi"
    echo "Publishing to TestPyPI"
elif [[ "$PUBLISH_TARGET" == "--github" ]]; then
    REPO="github"
    REPO_NAME="GitHub Packages"
    # Automatically get GitHub repo and branch information
    GITHUB_REPO=$(git config --get remote.origin.url | sed 's/.*github.com:\(.*\).git/\1/' | sed 's/.*github.com\/\(.*\).git/\1/')
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    # Check for .pypirc file first
    PYPIRC_FILE="$PROJECT_ROOT/.pypirc"
    if [ -f "$PYPIRC_FILE" ]; then
        echo "Found .pypirc file, checking for GitHub credentials..."
        PYPIRC_GITHUB_USER=$(grep -A 2 "\[github\]" "$PYPIRC_FILE" | grep username | sed 's/username = //')
        PYPIRC_GITHUB_TOKEN=$(grep -A 2 "\[github\]" "$PYPIRC_FILE" | grep password | sed 's/password = //')
        
        # Use credentials from .pypirc if they exist
        if [ -n "$PYPIRC_GITHUB_USER" ]; then
            GITHUB_USER=$PYPIRC_GITHUB_USER
        fi
        if [ -n "$PYPIRC_GITHUB_TOKEN" ]; then
            GITHUB_TOKEN=$PYPIRC_GITHUB_TOKEN
        fi
    else
        echo "No .pypirc file found, checking environment variables..."
    fi
    
    # If not found in .pypirc, try environment variables
    if [ -z "$GITHUB_USER" ]; then
        GITHUB_USER=${GITHUB_USERNAME:-$GH_USERNAME}
    fi
    if [ -z "$GITHUB_TOKEN" ]; then
        GITHUB_TOKEN=${GITHUB_TOKEN:-$GH_TOKEN}
    fi
    
    # If still not found, prompt user
    if [ -z "$GITHUB_USER" ]; then
        read -p "Enter GitHub username: " GITHUB_USER
    fi
    if [ -z "$GITHUB_TOKEN" ]; then
        read -sp "Enter GitHub Personal Access Token: " GITHUB_TOKEN
        echo
    fi
    INSTALL_CMD="pip install --index-url https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}/raw/${BRANCH}/dist/ project_src"
    TWINE_ARGS="--repository github"
    echo "Publishing to GitHub Packages"
else
    REPO="pypi"
    REPO_NAME="PyPI"
    INSTALL_CMD="pip install project_src"
    TWINE_ARGS="--repository pypi"
    echo "Publishing to PyPI"
fi

# Function to get current version from setup.py
get_current_version() {
    grep -m 1 'version="[^"]*"' setup.py | sed 's/.*version="\([^"]*\)".*/\1/'
}

# Function to update version in setup.py and pyproject.toml
update_version() {
    local new_version=$1
    local setup_file="$PROJECT_ROOT/setup.py"
    local pyproject_file="$PROJECT_ROOT/setup_config/pyproject.toml"

    # Update setup.py
    sed -i '' "s/version=\"[^\"]*\"/version=\"$new_version\"/" "$setup_file"

    # Update pyproject.toml if it exists
    if [ -f "$pyproject_file" ]; then
        sed -i '' "s/version[ ]*=[ ]*\"[^\"]*\"/version     = \"$new_version\"/" "$pyproject_file"
    fi

    echo "Version updated to $new_version"
}

# Get current version
CURRENT_VERSION=$(get_current_version)
echo "Current version: $CURRENT_VERSION"

# Ask for new version
read -p "Enter new version (leave blank to keep current): " NEW_VERSION
if [ -n "$NEW_VERSION" ] && [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
    update_version "$NEW_VERSION"
    VERSION="$NEW_VERSION"
else
    VERSION="$CURRENT_VERSION"
fi


# Clean previous builds
echo "Cleaning previous build artifacts..."
rm -rf dist build project_src.egg-info

# Install required build tools
echo "Installing/upgrading build tools..."
python -m pip install --upgrade pip build twine

# Build the package
echo "Building distribution packages..."
python -m build

# Upload to repository
echo "Uploading to ${REPO_NAME}..."

if [[ "$REPO" == "github" ]]; then
    echo "Publishing to GitHub Repository..."

    # Create a packages directory if it doesn't exist
    PACKAGES_DIR="$PROJECT_ROOT/packages"
    mkdir -p "$PACKAGES_DIR"

    # Copy the built packages to the packages directory
    cp "$PROJECT_ROOT/dist"/* "$PACKAGES_DIR/"

    # Create a README.md file in the packages directory with installation instructions
    cat > "$PACKAGES_DIR/README.md" << EOF
# project_src Package

## Version $VERSION

This directory contains the built packages for the project_src Python package.

## Installation

To install directly from this repository:

\`\`\`bash
pip install git+https://github.com/${GITHUB_REPO}.git
\`\`\`

Or download the wheel file and install it locally:

\`\`\`bash
pip install project_src-$VERSION-py3-none-any.whl
\`\`\`
EOF

    # Commit and push the changes
    cd "$PROJECT_ROOT"
    git add "packages/"
    git commit -m "Add package version $VERSION"

    # Push to GitHub using HTTPS with token
    REPO_URL="https://$GITHUB_USER:$GITHUB_TOKEN@github.com/${GITHUB_REPO}.git"
    git push "$REPO_URL" HEAD:$BRANCH

    echo "\nPackage published to GitHub Repository!"
    echo "You can install it with:"
    echo "pip install git+https://github.com/${GITHUB_REPO}.git"

    # Or use PyPI for regular publishing
else
    # Set environment variables for twine to use credentials from .pypirc
    export TWINE_USERNAME="__token__"
    export TWINE_PASSWORD=$(grep -A 2 "\[$REPO\]" "$PROJECT_ROOT/.pypirc" | grep password | sed 's/password = //')

    # Upload to PyPI or TestPyPI
    python -m twine upload $TWINE_ARGS dist/*

    echo "\nPackage uploaded to ${REPO_NAME}!"
    echo "You can install it with:"
    echo "$INSTALL_CMD"
fi

echo "Package uploaded successfully!"
echo "You can install it with:"
echo "$INSTALL_CMD"

echo "Process completed successfully!"
