#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Project Template Manager - Build and Install Script${NC}\n"

# Process command line arguments
IDE_ARG=""
PUBLISH_ARG=""
VERSION_ARG=""
PAT_ARG=""

# Parse command line arguments in any order
for arg in "$@"; do
    case $arg in
        --ide=*)
            IDE_ARG="${arg#*=}"
            ;;
        --action=*)
            PUBLISH_ARG="${arg#*=}"
            ;;
        --version=*)
            VERSION_ARG="${arg#*=}"
            ;;
        --token=*)
            PAT_ARG="${arg#*=}"
            ;;
        *)
            # For backward compatibility, try to guess based on position
            if [ -z "$IDE_ARG" ] && [[ "$arg" =~ ^(code|code-insiders|windsurf|windsurf-next|cursor|skip)$ ]]; then
                IDE_ARG="$arg"
            elif [ -z "$PUBLISH_ARG" ] && [[ "$arg" =~ ^(local|publish)$ ]]; then
                PUBLISH_ARG="$arg"
            elif [ -z "$VERSION_ARG" ] && [[ "$arg" =~ ^(patch|minor|major|none)$ ]]; then
                VERSION_ARG="$arg"
            elif [ -z "$PAT_ARG" ] && [ ${#arg} -gt 10 ]; then
                # Assuming PAT is longer than 10 chars
                PAT_ARG="$arg"
            else
                echo -e "${YELLOW}Warning: Unrecognized argument '$arg'${NC}"
            fi
            ;;
    esac
done

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

# Determine whether to package or publish
PUBLISH_CHOICE=""
if [ -n "$PUBLISH_ARG" ]; then
    if [ "$PUBLISH_ARG" == "local" ]; then
        PUBLISH_CHOICE="1"
    elif [ "$PUBLISH_ARG" == "publish" ]; then
        PUBLISH_CHOICE="2"
    else
        echo -e "${RED}Invalid publish argument: $PUBLISH_ARG. Must be 'local' or 'publish'.${NC}"
        exit 1
    fi
else
    # Ask whether to package and install locally, or publish to marketplace
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "1) Package and install locally"
    echo "2) Publish to VS Code Marketplace"

    read -p "Enter your choice (1-2): " PUBLISH_CHOICE
fi

# Handle based on the choice
if [ "$PUBLISH_CHOICE" == "1" ]; then
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

    # Determine IDE choice
    IDE_CHOICE=""
    if [ -n "$IDE_ARG" ]; then
        case "$IDE_ARG" in
            "code")
                IDE_CHOICE="1"
                ;;
            "code-insiders")
                IDE_CHOICE="2"
                ;;
            "windsurf")
                IDE_CHOICE="3"
                ;;
            "windsurf-next")
                IDE_CHOICE="4"
                ;;
            "cursor")
                IDE_CHOICE="5"
                ;;
            "skip")
                IDE_CHOICE="6"
                ;;
            *)
                echo -e "${RED}Invalid IDE argument: $IDE_ARG${NC}"
                echo -e "${YELLOW}Valid options: code, code-insiders, windsurf, windsurf-next, cursor, skip${NC}"
                exit 1
                ;;
        esac
    else
        # Ask the user which IDE they want to use
        echo -e "${BLUE}Please select which IDE you want to install the extension in:${NC}"
        echo "1) Visual Studio Code (code)"
        echo "2) Visual Studio Code Insiders (code-insiders)"
        echo "3) Windsurf (windsurf)"
        echo "4) Windsurf Next (windsurf-next)"
        echo "5) Cursor (cursor)"
        echo "6) Skip installation"

        read -p "Enter your choice (1-6): " IDE_CHOICE
    fi

    # Install based on user choice
    case $IDE_CHOICE in
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

elif [ "$PUBLISH_CHOICE" == "2" ]; then
    # Publishing to VS Code Marketplace
    echo -e "${BLUE}Publishing to VS Code Marketplace...${NC}"

    # Check if publisher is set in package.json
    PUBLISHER=$(grep -o '"publisher": "[^"]*"' package.json | cut -d'"' -f4)
    if [ -z "$PUBLISHER" ]; then
        echo -e "${RED}Error: publisher field not set in package.json${NC}"
        echo -e "${YELLOW}Please set the publisher field in package.json before publishing.${NC}"
        exit 1
    fi

    # Determine version increment choice
    VERSION_CHOICE=""
    if [ -n "$VERSION_ARG" ]; then
        case "$VERSION_ARG" in
            "patch")
                VERSION_CHOICE="1"
                ;;
            "minor")
                VERSION_CHOICE="2"
                ;;
            "major")
                VERSION_CHOICE="3"
                ;;
            "none")
                VERSION_CHOICE="4"
                ;;
            *)
                echo -e "${RED}Invalid version argument: $VERSION_ARG${NC}"
                echo -e "${YELLOW}Valid options: patch, minor, major, none${NC}"
                exit 1
                ;;
        esac
    else
        # Ask about version increment
        echo -e "${BLUE}What type of version increment would you like to make?${NC}"
        echo "1) Patch (1.0.0 -> 1.0.1) - for bugfixes"
        echo "2) Minor (1.0.0 -> 1.1.0) - for new features"
        echo "3) Major (1.0.0 -> 2.0.0) - for breaking changes"
        echo "4) None (use current version)"

        read -p "Enter your choice (1-4): " VERSION_CHOICE
    fi

    VERSION_FLAG=""
    case $VERSION_CHOICE in
        1)
            VERSION_FLAG="patch"
            ;;
        2)
            VERSION_FLAG="minor"
            ;;
        3)
            VERSION_FLAG="major"
            ;;
        4)
            VERSION_FLAG=""
            ;;
        *)
            echo -e "${RED}Invalid choice. Using current version.${NC}"
            VERSION_FLAG=""
            ;;
    esac

    # Get PAT from .env file if it exists, and no token was passed as argument
    if [ -z "$PAT_ARG" ]; then
        ENV_FILE="$(dirname "$0")/.env"
        if [ -f "$ENV_FILE" ]; then
            echo -e "${BLUE}Reading token from .env file...${NC}"
            # Source the .env file to load VSCE_PAT
            source "$ENV_FILE"
            if [ ! -z "$VSCE_PAT" ] && [ "$VSCE_PAT" != "your_personal_access_token_here" ]; then
                PAT_ARG="$VSCE_PAT"
                echo -e "${GREEN}Token found in .env file.${NC}"
            else
                echo -e "${YELLOW}No valid token found in .env file.${NC}"
            fi
        else
            echo -e "${YELLOW}No .env file found at $ENV_FILE${NC}"
        fi
    fi

    # Ask for personal access token if needed
    TOKEN_CHOICE=""
    if [ -n "$PAT_ARG" ]; then
        # Use provided token from command line or .env
        PAT="$PAT_ARG"
        TOKEN_CHOICE="1"
        echo -e "${BLUE}Using Personal Access Token...${NC}"
    else
        echo -e "${BLUE}Do you have a Personal Access Token (PAT) for publishing?${NC}"
        echo "1) Yes, I have a PAT"
        echo "2) No, I need to login first"

        read -p "Enter your choice (1-2): " TOKEN_CHOICE

        if [ "$TOKEN_CHOICE" == "1" ]; then
            read -p "Enter your Personal Access Token: " PAT
        fi
    fi

    if [ "$TOKEN_CHOICE" == "1" ]; then
        # Use existing token
        if [ -z "$PAT" ]; then
            echo -e "${RED}Error: No token provided. Exiting.${NC}"
            exit 1
        fi

        # Publish with token
        if [ -z "$VERSION_FLAG" ]; then
            echo -e "${BLUE}Publishing with current version...${NC}"
            if vsce publish -p "$PAT"; then
                echo -e "${GREEN}Extension published successfully!${NC}"
            else
                echo -e "${RED}Failed to publish extension. Check the error message above.${NC}"
                exit 1
            fi
        else
            echo -e "${BLUE}Publishing with ${VERSION_FLAG} version increment...${NC}"
            if vsce publish ${VERSION_FLAG} -p "$PAT"; then
                echo -e "${GREEN}Extension published successfully!${NC}"
            else
                echo -e "${RED}Failed to publish extension. Check the error message above.${NC}"
                exit 1
            fi
        fi
    elif [ "$TOKEN_CHOICE" == "2" ]; then
        # Login first
        echo -e "${BLUE}Logging in as publisher '${PUBLISHER}'...${NC}"
        echo -e "${YELLOW}You will be prompted to enter your Personal Access Token${NC}"
        echo -e "${YELLOW}If you don't have one, create it at: https://dev.azure.com/[your-org]/_usersSettings/tokens${NC}"
        echo -e "${YELLOW}Make sure to grant 'Marketplace' scope with 'Manage' permission${NC}"

        if vsce login "$PUBLISHER"; then
            echo -e "${GREEN}Login successful!${NC}"

            # Now publish
            if [ -z "$VERSION_FLAG" ]; then
                echo -e "${BLUE}Publishing with current version...${NC}"
                if vsce publish; then
                    echo -e "${GREEN}Extension published successfully!${NC}"
                else
                    echo -e "${RED}Failed to publish extension. Check the error message above.${NC}"
                    exit 1
                fi
            else
                echo -e "${BLUE}Publishing with ${VERSION_FLAG} version increment...${NC}"
                if vsce publish ${VERSION_FLAG}; then
                    echo -e "${GREEN}Extension published successfully!${NC}"
                else
                    echo -e "${RED}Failed to publish extension. Check the error message above.${NC}"
                    exit 1
                fi
            fi
        else
            echo -e "${RED}Login failed. Please try again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
    fi

    echo -e "${BLUE}Your extension should now be available on the VS Code Marketplace!${NC}"
    echo -e "${BLUE}It may take a few minutes to appear in search results.${NC}"
    echo -e "${BLUE}You can view your extensions at: ${NC}${YELLOW}https://marketplace.visualstudio.com/manage/publishers/${PUBLISHER}${NC}"

else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Process completed!${NC}"

# Print usage info if no arguments provided
if [ $# -eq 0 ]; then
    echo -e "\n${BLUE}Command line usage:${NC}"
    echo -e "./install.sh [options]"
    echo -e "\nOptions (can be provided in any order):"
    echo -e "  --ide=<ide>      : code, code-insiders, windsurf, windsurf-next, cursor, skip"
    echo -e "  --action=<action>: local, publish"
    echo -e "  --version=<ver>  : patch, minor, major, none (for publish only)"
    echo -e "  --token=<pat>    : Personal Access Token for publishing"
    echo -e "\nBackward compatibility: You can also use positional arguments:"
    echo -e "  ./install.sh <ide> <action> [version] [pat]"
    echo -e "\nNotes:"
    echo -e "  - You can store your Personal Access Token in a .env file in the root directory"
    echo -e "    with the format: VSCE_PAT=\"your_token_here\""
    echo -e "\nExamples:"
    echo -e "  ./install.sh --ide=cursor --action=local"
    echo -e "  ./install.sh --action=publish --version=patch --token=your_token"
    echo -e "  ./install.sh cursor local"
fi
