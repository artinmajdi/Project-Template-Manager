#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}===========================================================${NC}"
echo -e "${BLUE}          Environment Configuration Script                 ${NC}"
echo -e "${BLUE}===========================================================${NC}"
echo ""

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"

# Check if .env file already exists
ENV_FILE="$PROJECT_ROOT/.env"
ENV_TEMPLATE="$PROJECT_ROOT/setup_config/.env.example"

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}An .env file already exists at $ENV_FILE${NC}"
    echo -e "What would you like to do?"
    echo -e "${BLUE}1)${NC} Keep existing file"
    echo -e "${BLUE}2)${NC} Replace with template (current file will be backed up)"
    echo -e "${BLUE}3)${NC} Merge template with existing file (adds missing variables)"

    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            echo -e "${GREEN}Keeping existing .env file.${NC}"
            ;;
        2)
            echo -e "${YELLOW}Creating backup of existing .env file...${NC}"
            cp "$ENV_FILE" "$ENV_FILE.bak"
            echo -e "${GREEN}Backup created at $ENV_FILE.bak${NC}"

            echo -e "${YELLOW}Copying template to .env...${NC}"
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            echo -e "${GREEN}Template copied to $ENV_FILE.${NC}"
            ;;
        3)
            echo -e "${YELLOW}Merging template with existing .env file...${NC}"
            # Create temporary file
            TEMP_FILE=$(mktemp)
            # Copy existing file to temp
            cp "$ENV_FILE" "$TEMP_FILE"

            # Add variables from template that don't exist in current file
            while IFS= read -r line; do
                # Skip comments and empty lines
                if [[ $line == \#* ]] || [[ -z $(echo "$line" | tr -d '[:space:]') ]]; then
                    continue
                fi

                # Extract variable name (before = sign)
                var_name=$(echo "$line" | cut -d '=' -f 1)

                # Check if variable exists in current .env
                if ! grep -q "^${var_name}=" "$ENV_FILE"; then
                    echo "$line" >> "$TEMP_FILE"
                    echo -e "${GREEN}Added: $var_name${NC}"
                fi
            done < "$ENV_TEMPLATE"

            # Move temp file to .env
            mv "$TEMP_FILE" "$ENV_FILE"
            echo -e "${GREEN}Template merged with existing .env file.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Keeping existing .env file.${NC}"
            ;;
    esac
else
    echo -e "${YELLOW}No .env file found. Creating from template...${NC}"

    if [ -f "$ENV_TEMPLATE" ]; then
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        echo -e "${GREEN}Template copied to $ENV_FILE.${NC}"
    else
        echo -e "${RED}Error: Template file not found at $ENV_TEMPLATE${NC}"
        echo -e "${YELLOW}Creating empty .env file...${NC}"
        touch "$ENV_FILE"
        echo -e "${GREEN}Empty .env file created at $ENV_FILE.${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Do you want to edit the .env file now?${NC}"
echo -e "${BLUE}1)${NC} Yes, open in default editor"
echo -e "${BLUE}2)${NC} No, I'll edit it later"

read -p "Enter your choice (1-2): " edit_choice

case $edit_choice in
    1)
        # Determine which editor to use
        if [ -n "$EDITOR" ]; then
            $EDITOR "$ENV_FILE"
        elif command -v nano >/dev/null 2>&1; then
            nano "$ENV_FILE"
        elif command -v vim >/dev/null 2>&1; then
            vim "$ENV_FILE"
        elif command -v vi >/dev/null 2>&1; then
            vi "$ENV_FILE"
        else
            echo -e "${RED}No editor found. Please edit the file manually at $ENV_FILE${NC}"
        fi
        ;;
    *)
        echo -e "${YELLOW}You can edit the .env file later at $ENV_FILE${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}===========================================================${NC}"
echo -e "${GREEN}       Environment configuration completed!                ${NC}"
echo -e "${GREEN}===========================================================${NC}"

exit 0
