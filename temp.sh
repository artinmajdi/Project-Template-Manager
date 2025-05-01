#!/bin/bash
set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#==============================
# HELPER FUNCTIONS
#==============================

# Function to display messages with color
log_info() { echo -e "${BLUE}$1${NC}"; }
log_success() { echo -e "${GREEN}$1${NC}"; }
log_warning() { echo -e "${YELLOW}$1${NC}"; }
log_error() { echo -e "${RED}$1${NC}" >&2; }

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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
    echo "  --action=<action> : local, publish-vscode, publish-ovsx, publish-both"
    echo "  --version=<ver>   : patch, minor, major, none, github (use latest GitHub tag)"
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
    echo "  ./install.sh --action=publish-both --version=patch --token=your_vscode_token --ovsx-token=your_ovsx_token"
    echo "  ./install.sh --action=publish-vscode --version=github"
    echo "  ./install.sh cursor local"
}

# Function to load tokens from .env file
load_tokens_from_env() {
    # Use the PROJECT_ROOT variable to locate the .env file
    local env_file="$PROJECT_ROOT/.env"

    if [ -f "$env_file" ]; then
        log_info "Reading tokens from .env file..."
        # Source the .env file to load tokens
        source "$env_file"

        # Check for VS Code Marketplace token
        if [ -z "$PAT_ARG" ] && [ ! -z "$VSCE_PAT" ] && [ "$VSCE_PAT" != "your_vscode_token_here" ] && [ "$VSCE_PAT" != "your_personal_access_token_here" ]; then
            PAT_ARG="$VSCE_PAT"
            log_success "VS Code Marketplace token found in .env file."
        elif [ -z "$PAT_ARG" ]; then
            log_warning "No valid VS Code Marketplace token found in .env file."
        fi

        # Check for Open VSX Registry token
        if [ -z "$OVSX_PAT_ARG" ] && [ ! -z "$OVSX_PAT" ] && [ "$OVSX_PAT" != "your_ovsx_token_here" ] && [ "$OVSX_PAT" != "your_open_vsx_token_here" ]; then
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

# Function to get the latest GitHub release tag
get_github_latest_tag() {
    local repo_url=$(grep -o '"repository": "[^"]*"' package.json | cut -d'"' -f4)

    if [ -z "$repo_url" ]; then
        log_error "Error: repository field not set in package.json"
        return 1
    fi

    # Extract username and repo name from the URL
    local repo_path=$(echo "$repo_url" | sed -e 's|^https://github.com/||' -e 's|.git$||')

    if ! command_exists "curl" || ! command_exists "jq"; then
        log_warning "curl or jq is not installed. Cannot fetch GitHub tags."
        log_info "Installing required tools..."

        if command_exists "apt-get"; then
            sudo apt-get update && sudo apt-get install -y curl jq
        elif command_exists "brew"; then
            brew install curl jq
        elif command_exists "yum"; then
            sudo yum install -y curl jq
        else
            log_error "Cannot install required tools. Please install curl and jq manually."
            return 1
        fi
    fi

    log_info "Fetching latest release tag from GitHub for $repo_path..."

    local latest_tag=$(curl -s "https://api.github.com/repos/$repo_path/releases/latest" | jq -r '.tag_name')

    if [ -z "$latest_tag" ] || [ "$latest_tag" == "null" ]; then
        log_error "Failed to fetch latest GitHub release tag."
        return 1
    fi

    # Remove 'v' prefix if present
    latest_tag=${latest_tag#v}

    log_success "Latest GitHub release tag: $latest_tag"
    echo "$latest_tag"
    return 0
}

# Function to update version in package.json
update_version_to_github_tag() {
    local github_tag=$(get_github_latest_tag)

    if [ $? -ne 0 ]; then
        log_error "Failed to get GitHub tag. Using current version instead."
        return 1
    fi

    # Update version in package.json
    local current_version=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)

    if [ "$current_version" == "$github_tag" ]; then
        log_info "Current version ($current_version) already matches GitHub tag."
        return 0
    fi

    log_info "Updating version from $current_version to $github_tag..."

    # Use sed to update the version in package.json
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS version of sed requires slightly different syntax
        sed -i '' "s/\"version\": \"$current_version\"/\"version\": \"$github_tag\"/" package.json
    else
        # Linux version
        sed -i "s/\"version\": \"$current_version\"/\"version\": \"$github_tag\"/" package.json
    fi

    if [ $? -eq 0 ]; then
        log_success "Version updated successfully to $github_tag"
        return 0
    else
        log_error "Failed to update version in package.json"
        return 1
    fi
}

# Function to publish to VS Code Marketplace
publish_to_vscode() {
    local version_flag="$1"
    local pat="$2"

    # Check if token is provided
    if [ -z "$pat" ]; then
        log_error "Error: No VS Code Marketplace token provided"
        return 1
    fi

    # Publish based on version flag
    if [ "$version_flag" == "github" ]; then
        log_info "Updating to GitHub release version before publishing..."
        update_version_to_github_tag

        if [ $? -ne 0 ]; then
            log_warning "Failed to update to GitHub version. Publishing with current version..."
            version_flag=""
        else
            version_flag=""  # We've already updated the version, so don't pass a flag
        fi
    fi

    if [ -z "$version_flag" ]; then
        log_info "Publishing with current version to VS Code Marketplace..."
        if vsce publish -p "$pat"; then
            log_success "Extension published successfully to VS Code Marketplace!"
            return 0
        else
            log_error "Failed to publish extension to VS Code Marketplace. Check the error message above."
            return 1
        fi
    else
        log_info "Publishing with ${version_flag} version increment to VS Code Marketplace..."
        if vsce publish ${version_flag} -p "$pat"; then
            log_success "Extension published successfully to VS Code Marketplace!"
            return 0
        else
            log_error "Failed to publish extension to VS Code Marketplace. Check the error message above."
            return 1
        fi
    fi
}

# Function to publish to Open VSX Registry
publish_to_ovsx() {
    local vsix_file="$1"
    local token="$2"

    # Check if we have a token
    if [ -z "$token" ]; then
        log_error "Error: No Open VSX Registry token provided."
        log_warning "Please provide a token using --ovsx-token or add OVSX_PAT to your .env file."
        create_sample_env_file "$PROJECT_ROOT/.env"
        return 1
    fi

    # Publish to Open VSX Registry
    log_info "Publishing to Open VSX Registry..."
    if ovsx publish "$vsix_file" -p "$token"; then
        log_success "Successfully published to Open VSX Registry!"
        return 0
    else
        log_error "Failed to publish to Open VSX Registry. Check the error message above."
        return 1
    fi
}

# Function to handle local installation
handle_local_install() {
    local ide_choice="$1"

    # Package the extension
    log_info "Packaging the extension..."
    vsce package

    # Check if the VSIX file was created
    VSIX_FILE=$(ls -t *.vsix | head -n 1)
    if [ -z "$VSIX_FILE" ]; then
        log_error "Error: Failed to create VSIX file. Check for errors above."
        exit 1
    fi

    log_success "Successfully created ${VSIX_FILE}\n"

    if [ -n "$ide_choice" ] && [ "$ide_choice" == "6" -o "$ide_choice" == "skip" ]; then
        log_warning "Skipping installation. You can manually install later with:"
        echo -e "ide_command --install-extension ${VSIX_FILE}"
        return 0
    fi

    # If IDE choice not provided, ask user
    if [ -z "$ide_choice" ]; then
        # Ask the user which IDE they want to use
        log_info "Please select which IDE you want to install the extension in:"
        echo "1) Visual Studio Code (code)"
        echo "2) Visual Studio Code Insiders (code-insiders)"
        echo "3) Windsurf (windsurf)"
        echo "4) Windsurf Next (windsurf-next)"
        echo "5) Cursor (cursor)"
        echo "6) Skip installation"

        read -p "Enter your choice (1-6): " ide_choice
    fi

    # Map the choice to IDE command
    case $ide_choice in
        1|"code")
            IDE_CMD="code"
            ;;
        2|"code-insiders")
            IDE_CMD="code-insiders"
            ;;
        3|"windsurf")
            IDE_CMD="windsurf"
            ;;
        4|"windsurf-next")
            IDE_CMD="windsurf-next"
            ;;
        5|"cursor")
            IDE_CMD="cursor"
            ;;
        6|"skip")
            log_warning "Skipping installation. You can manually install later with:"
            echo -e "ide_command --install-extension ${VSIX_FILE}"
            return 0
            ;;
        *)
            log_error "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    # Check if the IDE command exists
    if ! command -v $IDE_CMD &> /dev/null; then
        log_error "Error: $IDE_CMD command not found. Please make sure it's installed and in your PATH."
        log_warning "You can manually install later with:"
        echo -e "$IDE_CMD --install-extension ${VSIX_FILE}"
        exit 1
    fi

    # Install the extension
    log_info "Installing extension in $IDE_CMD..."
    $IDE_CMD --install-extension "${VSIX_FILE}"

    # Extract version from package.json
    VERSION=$(grep -o '"version": "[^"]*"' package.json | cut -d'"' -f4)

    if [ $? -eq 0 ]; then
        log_success "Extension installed successfully in $IDE_CMD!"
        echo -e "\n${BLUE}Next steps:${NC}"
        echo -e "1. Add your template files to the extension directory"
        echo -e "2. Restart your IDE if it's already running"
        echo -e "3. Access the commands from the Command Palette (Cmd/Ctrl+Shift+P):"
        echo -e "   - ${YELLOW}Project Template: Create Full Project${NC}"
        echo -e "   - ${YELLOW}Project Template: Add Files/Folders from Template${NC}"

        # Print extension directory path
        EXTENSION_DIR=""
        PUBLISHER=$(grep -o '"publisher": "[^"]*"' package.json | cut -d'"' -f4)

        case "$IDE_CMD" in
            "code" | "code-insiders")
                if [ "$(uname)" == "Darwin" ]; then
                    EXTENSION_DIR="~/.vscode/extensions/${PUBLISHER}.project-template-manager-${VERSION}"
                elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
                    EXTENSION_DIR="~/.vscode/extensions/${PUBLISHER}.project-template-manager-${VERSION}"
                elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
                    EXTENSION_DIR="%USERPROFILE%\\.vscode\\extensions\\${PUBLISHER}.project-template-manager-${VERSION}"
                fi
                ;;
            "cursor")
                if [ "$(uname)" == "Darwin" ]; then
                    EXTENSION_DIR="~/.cursor/extensions/${PUBLISHER}.project-template-manager-${VERSION}"
                elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
                    EXTENSION_DIR="~/.cursor/extensions/${PUBLISHER}.project-template-manager-${VERSION}"
                elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
                    EXTENSION_DIR="%USERPROFILE%\\.cursor\\extensions\\${PUBLISHER}.project-template-manager-${VERSION}"
                fi
                ;;
            *)
                EXTENSION_DIR="~/.${IDE_CMD}/extensions/${PUBLISHER}.project-template-manager-${VERSION}"
                ;;
        esac

        if [ ! -z "$EXTENSION_DIR" ]; then
            log_info "The extension is installed at: ${YELLOW}$EXTENSION_DIR${NC}"
        fi
    else
        log_error "Failed to install the extension. Please try installing manually:"
        echo -e "$IDE_CMD --install-extension ${VSIX_FILE}"
    fi
}

#==============================
# MAIN SCRIPT
#==============================

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
            elif [ -z "$PUBLISH_ARG" ] && [[ "$arg" =~ ^(local|publish-vscode|publish-ovsx|publish-both|publish)$ ]]; then
                PUBLISH_ARG="$arg"
                # For backwards compatibility
                if [ "$PUBLISH_ARG" == "publish" ]; then
                    PUBLISH_ARG="publish-both"
                fi
            elif [ -z "$VERSION_ARG" ] && [[ "$arg" =~ ^(patch|minor|major|none|github)$ ]]; then
                VERSION_ARG="$arg"
            elif [ -z "$PAT_ARG" ] && [ ${#arg} -gt 10 ]; then
                # Assuming PAT is longer than 10 chars
                PAT_ARG="$arg"
            elif [ -z "$OVSX_ARG" ] && [[ "$arg" =~ ^(yes|no)$ ]]; then
                OVSX_ARG="$arg"
            else
                log_warning "Warning: Unrecognized argument '$arg'"
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
    case "$PUBLISH_ARG" in
        "local")
            PUBLISH_CHOICE="1"
            ;;
        "publish-vscode")
            PUBLISH_CHOICE="2"
            ;;
        "publish-ovsx")
            PUBLISH_CHOICE="3"
            ;;
        "publish-both")
            PUBLISH_CHOICE="4"
            ;;
        *)
            log_error "Invalid publish argument: $PUBLISH_ARG. Must be 'local', 'publish-vscode', 'publish-ovsx', or 'publish-both'."
            exit 1
            ;;
    esac
else
    # Ask what to do
    log_info "What would you like to do?"
    echo "1) Package and install locally"
    echo "2) Publish to VS Code Marketplace only"
    echo "3) Publish to Open VSX Registry only"
    echo "4) Publish to both marketplaces"

    read -p "Enter your choice (1-4): " PUBLISH_CHOICE
fi

# Load tokens from .env file
load_tokens_from_env

# Handle based on the choice
case "$PUBLISH_CHOICE" in
    "1")
        # Local installation
        handle_local_install "$IDE_ARG"
        ;;

    "2"|"3"|"4")
        # Publishing to VS Code Marketplace and/or Open VSX Registry
        # Check if publisher is set in package.json
        PUBLISHER=$(grep -o '"publisher": "[^"]*"' package.json | cut -d'"' -f4)
        if [ -z "$PUBLISHER" ]; then
            log_error "Error: publisher field not set in package.json"
            log_warning "Please set the publisher field in package.json before publishing."
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
                "github")
                    VERSION_CHOICE="5"
                    ;;
                *)
                    log_error "Invalid version argument: $VERSION_ARG"
                    log_warning "Valid options: patch, minor, major, none, github"
                    exit 1
                    ;;
            esac
        else
            # Ask about version increment
            log_info "What type of version increment would you like to make?"
            echo "1) Patch (1.0.0 -> 1.0.1) - for bugfixes"
            echo "2) Minor (1.0.0 -> 1.1.0) - for new features"
            echo "3) Major (1.0.0 -> 2.0.0) - for breaking changes"
            echo "4) None (use current version)"
            echo "5) GitHub (use latest GitHub release tag)"

            read -p "Enter your choice (1-5): " VERSION_CHOICE
        fi

        # Set version flag based on choice
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
            5)
                VERSION_FLAG="github"
                ;;
            *)
                log_error "Invalid choice. Using current version."
                VERSION_FLAG=""
                ;;
        esac

        # If no tokens were found and .env doesn't exist, create a sample one
        if [ -z "$PAT_ARG" ] && [ -z "$OVSX_PAT_ARG" ] && [ ! -f "$PROJECT_ROOT/.env" ]; then
            create_sample_env_file "$PROJECT_ROOT/.env"
        fi

        # Publish based on user choice
        if [ "$PUBLISH_CHOICE" == "2" ] || [ "$PUBLISH_CHOICE" == "4" ]; then
            # Publish to VS Code Marketplace
            TOKEN_CHOICE=""
            if [ -n "$PAT_ARG" ]; then
                # Use provided token from command line or .env
                PAT="$PAT_ARG"
                TOKEN_CHOICE="1"
                log_info "Using Personal Access Token for VS Code Marketplace..."
            else
                log_info "Do you have a Personal Access Token (PAT) for VS Code Marketplace?"
                echo "1) Yes, I have a PAT"
                echo "2) No, I need to login first"

                read -p "Enter your choice (1-2): " TOKEN_CHOICE

                if [ "$TOKEN_CHOICE" == "1" ]; then
                    read -p "Enter your Personal Access Token: " PAT
                fi
            fi

            if [ "$TOKEN_CHOICE" == "1" ]; then
                # Use existing token for VS Code Marketplace
                if [ -z "$PAT" ]; then
                    log_error "Error: No token provided for VS Code Marketplace. Exiting."
                    exit 1
                fi

                # Publish to VS Code Marketplace
                publish_to_vscode "$VERSION_FLAG" "$PAT" || exit 1

            elif [ "$TOKEN_CHOICE" == "2" ]; then
                # Login first for VS Code Marketplace
                log_info "Logging in as publisher '${PUBLISHER}'..."
                log_warning "You will be prompted to enter your Personal Access Token"
                log_warning "If you don't have one, create it at: https://dev.azure.com/[your-org]/_usersSettings/tokens"
                log_warning "Make sure to grant 'Marketplace' scope with 'Manage' permission"

                if vsce login "$PUBLISHER"; then
                    log_success "Login successful!"

                    # Now publish to VS Code
                    if [ "$VERSION_FLAG" == "github" ]; then
                        # Handle GitHub versioning
                        update_version_to_github_tag
                        if [ $? -eq 0 ]; then
                            if vsce publish; then
                                log_success "Extension published successfully to VS Code Marketplace!"
                            else
                                log_error "Failed to publish extension to VS Code Marketplace."
                                exit 1
                            fi
                        else
                            log_error "Failed to update to GitHub version. Exiting."
                            exit 1
                        fi
                    elif [ -z "$VERSION_FLAG" ]; then
                        if vsce publish; then
                            log_success "Extension published successfully to VS Code Marketplace!"
                        else
                            log_error "Failed to publish extension to VS Code Marketplace."
                            exit 1
                        fi
                    else
                        if vsce publish ${VERSION_FLAG}; then
                            log_success "Extension published successfully to VS Code Marketplace!"
                        else
                            log_error "Failed to publish extension to VS Code Marketplace."
                            exit 1
                        fi
                    fi
                else
                    log_error "Login failed. Please try again."
                    exit 1
                fi
            else
                log_error "Invalid choice. Exiting."
                exit 1
            fi

            log_info "Your extension should now be available on the VS Code Marketplace!"
            log_info "It may take a few minutes to appear in search results."
            log_info "You can view your extensions at: ${YELLOW}https://marketplace.visualstudio.com/manage/publishers/${PUBLISHER}${NC}"
        fi

        if [ "$PUBLISH_CHOICE" == "3" ] || [ "$PUBLISH_CHOICE" == "4" ]; then
            # Publish to Open VSX Registry
            log_info "Publishing to Open VSX Registry..."

            # If we're only publishing to OVSX (choice 3) and version is github, update version
            if [ "$PUBLISH_CHOICE" == "3" ] && [ "$VERSION_FLAG" == "github" ]; then
                update_version_to_github_tag
                if [ $? -ne 0 ]; then
                    log_error "Failed to update to GitHub version. Exiting."
                    exit 1
                fi
            fi

            # Get the VSIX file
            VSIX_FILE=$(ensure_vsix_file)
            if [ $? -ne 0 ]; then
                exit 1
            fi

            # If we don't have a token, ask for it
            if [ -z "$OVSX_PAT_ARG" ]; then
                log_info "A token is required for publishing to Open VSX Registry."
                read -p "Enter your Open VSX Registry Token: " OVSX_PAT_ARG
            fi

            # Publish to Open VSX
            publish_to_ovsx "$VSIX_FILE" "$OVSX_PAT_ARG" || exit 1
        fi
        ;;

    *)
        log_error "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo -e "\n${GREEN}Process completed!${NC}"

# Print usage info if no arguments provided
if [ $# -eq 0 ]; then
    show_usage
fi
