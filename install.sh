#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Project Template Manager - Build and Install Script${NC}\n"

# Navigate to the vscode-extension directory
cd "$(dirname "$0")/vscode-extension"

# Check if license file exists in the correct location
if [ ! -f "LICENSE" ]; then
    echo -e "${RED}Error: License file not found at vscode-extension/LICENSE${NC}"
    echo -e "${YELLOW}Please make sure the license file is in the correct location before continuing.${NC}"
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed. Please install Node.js before continuing.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed. Please install npm before continuing.${NC}"
    exit 1
fi

# Check if vsce is installed, if not, install it
if ! command -v vsce &> /dev/null; then
    echo -e "${YELLOW}vsce not found. Installing...${NC}"
    npm install -g @vscode/vsce
fi

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
npm install

# Compile TypeScript
echo -e "${BLUE}Compiling TypeScript...${NC}"
npm run compile

# Package the extension
echo -e "${BLUE}Packaging the extension...${NC}"
vsce package

# Check if the VSIX file was created
VSIX_FILE=$(ls -t *.vsix | head -n 1)
if [ -z "$VSIX_FILE" ]; then
    echo -e "${RED}Error: Failed to create VSIX file. Check for errors above.${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully created ${VSIX_FILE}${NC}\n"

# Ask the user which IDE they want to use
echo -e "${BLUE}Please select which IDE you want to install the extension in:${NC}"
echo "1) Visual Studio Code (code)"
echo "2) Visual Studio Code Insiders (code-insiders)"
echo "3) Windsurf (windsurf)"
echo "4) Windsurf Next (windsurf-next)"
echo "5) Cursor (cursor)"
echo "6) Skip installation"

read -p "Enter your choice (1-6): " choice

# Install based on user choice
case $choice in
    1)
        IDE_CMD="code"
        ;;
    2)
        IDE_CMD="code-insiders"
        ;;
    3)
        IDE_CMD="windsurf"
        ;;
    4)
        IDE_CMD="windsurf-next"
        ;;
    5)
        IDE_CMD="cursor"
        ;;
    6)
        echo -e "${YELLOW}Skipping installation. You can manually install later with:${NC}"
        echo -e "ide_command --install-extension ${VSIX_FILE}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

# Check if the IDE command exists
if ! command -v $IDE_CMD &> /dev/null; then
    echo -e "${RED}Error: $IDE_CMD command not found. Please make sure it's installed and in your PATH.${NC}"
    echo -e "${YELLOW}You can manually install later with:${NC}"
    echo -e "$IDE_CMD --install-extension ${VSIX_FILE}"
    exit 1
fi

# Install the extension
echo -e "${BLUE}Installing extension in $IDE_CMD...${NC}"
$IDE_CMD --install-extension "${VSIX_FILE}"

# Extract version from package.json
VERSION=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Extension installed successfully in $IDE_CMD!${NC}"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "1. Add your template files to the extension directory"
    echo -e "2. Restart your IDE if it's already running"
    echo -e "3. Access the commands from the Command Palette (Cmd/Ctrl+Shift+P):"
    echo -e "   - ${YELLOW}Project Template: Create Full Project${NC}"
    echo -e "   - ${YELLOW}Project Template: Add Files/Folders from Template${NC}"

    # Print extension directory path
    EXTENSION_DIR=""
    case "$IDE_CMD" in
        "code" | "code-insiders")
            if [ "$(uname)" == "Darwin" ]; then
                EXTENSION_DIR="~/.vscode/extensions/artinmajdi.project-template-manager-${VERSION}"
            elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
                EXTENSION_DIR="~/.vscode/extensions/artinmajdi.project-template-manager-${VERSION}"
            elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
                EXTENSION_DIR="%USERPROFILE%\\.vscode\\extensions\\artinmajdi.project-template-manager-${VERSION}"
            fi
            ;;
        "cursor")
            if [ "$(uname)" == "Darwin" ]; then
                EXTENSION_DIR="~/.cursor/extensions/artinmajdi.project-template-manager-${VERSION}"
            elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
                EXTENSION_DIR="~/.cursor/extensions/artinmajdi.project-template-manager-${VERSION}"
            elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
                EXTENSION_DIR="%USERPROFILE%\\.cursor\\extensions\\artinmajdi.project-template-manager-${VERSION}"
            fi
            ;;
        *)
            EXTENSION_DIR="~/.${IDE_CMD}/extensions/artinmajdi.project-template-manager-${VERSION}"
            ;;
    esac

    if [ ! -z "$EXTENSION_DIR" ]; then
        echo -e "${BLUE}The extension is installed at: ${YELLOW}$EXTENSION_DIR${NC}"
    fi
else
    echo -e "${RED}Failed to install the extension. Please try installing manually:${NC}"
    echo -e "$IDE_CMD --install-extension ${VSIX_FILE}"
fi

echo -e "\n${GREEN}Build and packaging process completed!${NC}"
