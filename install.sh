#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display messages with color
log_info() { echo -e "${BLUE}$1${NC}"; }
log_success() { echo -e "${GREEN}$1${NC}"; }
log_warning() { echo -e "${YELLOW}$1${NC}"; }
log_error() { echo -e "${RED}$1${NC}" >&2; }

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log_info "Project Template Manager - Build and Install Script\n"

# Process command line arguments
IDE_ARG=""
PUBLISH_ARG=""
VERSION_ARG=""
PAT_ARG=""
OVSX_ARG=""
OVSX_PAT_ARG=""


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
        --ovsx=*)
            OVSX_ARG="${arg#*=}"
            ;;
        --ovsx-token=*)
            OVSX_PAT_ARG="${arg#*=}"
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
            elif [ -z "$OVSX_ARG" ] && [[ "$arg" =~ ^(yes|no)$ ]]; then
                OVSX_ARG="$arg"
            else
                echo -e "${YELLOW}Warning: Unrecognized argument '$arg'${NC}"
            fi
            ;;
    esac
done

# Store the project root directory
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Navigate to the vscode-extension directory
cd "$PROJECT_ROOT/vscode-extension"

# Check if license file exists in the correct location
if [ ! -f "LICENSE" ]; then
    log_error "Error: License file not found at vscode-extension/LICENSE"
    log_warning "Please make sure the license file is in the correct location before continuing."
    exit 1
fi

# Check for required dependencies
for cmd in node npm; do
    if ! command_exists "$cmd"; then
        log_error "Error: $cmd is not installed. Please install $cmd before continuing."
        exit 1
    fi
done

# Install required CLI tools if needed
for tool in {"vsce":"@vscode/vsce","ovsx":"ovsx"}; do
    name=${tool%:*}
    package=${tool#*:}
    if ! command_exists "$name"; then
        log_warning "$name not found. Installing..."
        npm install -g "$package"
        if ! command_exists "$name"; then
            log_error "Failed to install $name. Please install it manually: npm install -g $package"
            exit 1
        else
            log_success "$name installed successfully."
        fi
    fi
done

# Install dependencies and compile TypeScript
log_info "Installing dependencies..."
npm install

log_info "Compiling TypeScript..."
npm run compile || { log_error "TypeScript compilation failed."; exit 1; }

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
    # Ask whether to package and install locally, or publish to marketplaces
    echo -e "${BLUE}What would you like to do?${NC}"
    echo "1) Package and install locally"
    echo "2) Publish to VS Code and Open VSX Marketplaces"

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

    # Function to load tokens from .env file
    load_tokens_from_env() {
        # Use the PROJECT_ROOT variable to locate the .env file
        local env_file="$PROJECT_ROOT/.env"
        
        if [ -f "$env_file" ]; then
            log_info "Reading tokens from .env file..."
            # Source the .env file to load tokens
            source "$env_file"

            # Check for VS Code Marketplace token
            if [ -z "$PAT_ARG" ] && [ ! -z "$VSCE_PAT" ] && [ "$VSCE_PAT" != "your_personal_access_token_here" ]; then
                PAT_ARG="$VSCE_PAT"
                log_success "VS Code Marketplace token found in .env file."
            elif [ -z "$PAT_ARG" ]; then
                log_warning "No valid VS Code Marketplace token found in .env file."
            fi

            # Check for Open VSX Registry token
            if [ -z "$OVSX_PAT_ARG" ] && [ ! -z "$OVSX_PAT" ] && [ "$OVSX_PAT" != "your_open_vsx_token_here" ]; then
                OVSX_PAT_ARG="$OVSX_PAT"
                log_success "Open VSX Registry token found in .env file."
            elif [ -z "$OVSX_PAT_ARG" ]; then
                log_warning "No valid Open VSX Registry token found in .env file."
            fi
            
            return 0
        else
            log_warning "No .env file found at $env_file"
            return 1
        fi
    }
    
    # Load tokens from .env file
    load_tokens_from_env
    
    # If no tokens were found and .env doesn't exist, create a sample one
    if [ -z "$PAT_ARG" ] && [ -z "$OVSX_PAT_ARG" ] && [ ! -f "$PROJECT_ROOT/.env" ]; then
        create_sample_env_file "$PROJECT_ROOT/.env"
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

    # Automatically publish to Open VSX Registry (unless explicitly disabled)
    OVSX_CHOICE="1" # Default to yes
    if [ -n "$OVSX_ARG" ] && [ "$OVSX_ARG" == "no" ]; then
        OVSX_CHOICE="2" # Only skip if explicitly set to no
        echo -e "${YELLOW}Skipping Open VSX Registry publication as requested.${NC}"
    fi

    if [ "$OVSX_CHOICE" == "1" ]; then
        echo -e "${BLUE}Publishing to Open VSX Registry...${NC}"
        # Function to ensure we have a VSIX file
        ensure_vsix_file() {
            # Find the latest vsix file in a cross-platform way
            local vsix_file=""
            
            # Check if we're on macOS or Linux
            if [[ "$(uname)" == "Darwin" ]]; then
                # macOS version
                vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -n1 | cut -d' ' -f2-)
            else
                # Linux version (with -printf)
                vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)
                
                # If the above fails, try a more compatible approach
                if [ -z "$vsix_file" ]; then
                    vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f | xargs ls -t 2>/dev/null | head -n1)
                fi
            fi
            
            if [ -z "$vsix_file" ]; then
                log_warning "No .vsix file found. Packaging extension..."
                if vsce package; then
                    # Try to find the file again after packaging
                    if [[ "$(uname)" == "Darwin" ]]; then
                        vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f -exec stat -f "%m %N" {} \; | sort -nr | head -n1 | cut -d' ' -f2-)
                    else
                        vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f -printf "%T@ %p\n" 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)
                        if [ -z "$vsix_file" ]; then
                            vsix_file=$(find . -maxdepth 1 -name "*.vsix" -type f | xargs ls -t 2>/dev/null | head -n1)
                        fi
                    fi
                    
                    if [ -z "$vsix_file" ]; then
                        log_error "Error: Failed to create VSIX file. Check for errors above."
                        return 1
                    fi
                else
                    log_error "Error: Failed to package extension. Check for errors above."
                    return 1
                fi
            fi
            
            # Return the VSIX file path
            echo "${vsix_file#./}"
            return 0
        }
        
        # Get the VSIX file
        VSIX_FILE=$(ensure_vsix_file)
        if [ $? -ne 0 ]; then
            exit 1
        fi

        # Function to publish to Open VSX Registry
        publish_to_ovsx() {
            local vsix_file="$1"
            local token="$2"
            
            # Check if we have a token
            if [ -z "$token" ]; then
                log_error "Error: No Open VSX Registry token provided."
                log_warning "Please provide a token using --ovsx-token or add OVSX_PAT to your .env file."
                
                # Create sample .env file if it doesn't exist
                create_sample_env_file "$PROJECT_ROOT/.env"
                
                return 1
            fi

            # Publish to Open VSX Registry
            log_info "Publishing to Open VSX Registry..."
            if ovsx publish "$vsix_file" -p "$token"; then
                log_success "Successfully published to Open VSX Registry!"
                log_info "Your extension should now be available on both marketplaces!"
                return 0
            else
                log_error "Failed to publish to Open VSX Registry. Check the error message above."
                return 1
            fi
        }
        
        # Publish to Open VSX Registry
        publish_to_ovsx "$VSIX_FILE" "$OVSX_PAT_ARG" || exit 1
    else
        echo -e "${YELLOW}Skipping publication to Open VSX Registry.${NC}"
    fi

else
    echo -e "${RED}Invalid choice. Exiting.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Process completed!${NC}"

# Function to create a sample .env file if it doesn't exist
create_sample_env_file() {
    local env_file="$1"
    if [ ! -f "$env_file" ]; then
        log_warning "Creating sample .env file at $env_file"
        cat > "$env_file" << EOL
# VS Code Marketplace Personal Access Token
VSCE_PAT="your_vscode_token_here"

# Open VSX Registry Personal Access Token
OVSX_PAT="your_ovsx_token_here"
EOL
        log_info "Sample .env file created. Please edit it with your actual tokens."
    fi
}

# Function to display usage information
show_usage() {
    log_info "\nCommand line usage:"
    echo "./install.sh [options]"
    
    log_info "\nOptions (can be provided in any order):"
    echo "  --ide=<ide>       : code, code-insiders, windsurf, windsurf-next, cursor, skip"
    echo "  --action=<action> : local, publish"
    echo "  --version=<ver>   : patch, minor, major, none (for publish only)"
    echo "  --token=<pat>     : Personal Access Token for VS Code Marketplace"
    echo "  --ovsx=<option>   : yes, no (default: yes for publish action)"
    echo "  --ovsx-token=<pat>: Personal Access Token for Open VSX Registry"
    
    log_info "\nBackward compatibility: You can also use positional arguments:"
    echo "  ./install.sh <ide> <action> [version] [pat]"
    
    log_info "\nNotes:"
    echo "  - You can store your Personal Access Tokens in a .env file in the root directory"
    echo "    with the format:"
    echo "    VSCE_PAT=\"your_vscode_token_here\""
    echo "    OVSX_PAT=\"your_ovsx_token_here\""
    
    log_info "\nExamples:"
    echo "  ./install.sh --ide=cursor --action=local"
    echo "  ./install.sh --action=publish --version=patch --token=your_vscode_token --ovsx-token=your_ovsx_token"
    echo "  ./install.sh cursor local"
}

# Print usage info if no arguments provided
if [ $# -eq 0 ]; then
    show_usage
fi
