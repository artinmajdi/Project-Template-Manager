#!/bin/bash
# install.sh - A streamlined script to run a TSX file in a React environment
# Created on April 28, 2025

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Print header
echo -e "${BOLD}${BLUE}=================================================${RESET}"
echo -e "${BOLD}${BLUE}🚀 React TSX Website Runner${RESET}"
echo -e "${BOLD}${BLUE}=================================================${RESET}"
echo ""

# ===== UTILITY FUNCTIONS =====

# Display error and exit
error_exit() {
    echo -e "${RED}❌ $1${RESET}"
    exit 1
}

# Display warning
show_warning() {
    echo -e "${YELLOW}⚠️ $1${RESET}"
}

# Display success
show_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

# Display info
show_info() {
    echo -e "${BLUE}ℹ️ $1${RESET}"
}

# Check for required dependencies
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        error_exit "Required dependency $1 is not installed.\nPlease install it with: $2"
    fi
}

# Display TSX files and get user selection
select_tsx_file() {
    local files=("$@")
    local count=${#files[@]}

    echo -e "${BOLD}Found $count TSX files:${RESET}"
    for i in "${!files[@]}"; do
        # Display file size and last modified date
        file_info=$(ls -lh "${files[$i]}" | awk '{print $5, $6, $7, $8}')
        echo -e "[$((i+1))] ${BOLD}${files[$i]}${RESET} ($file_info)"
    done

    echo ""
    echo -e "Please select a file by number (1-$count):"
    read -r selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le $count ]]; then
        echo -e "${GREEN}✅ Selected: ${files[$((selection-1))]}${RESET}"
        echo ""
        echo "${files[$((selection-1))]}"
    else
        error_exit "Invalid selection."
    fi
}

# Cross-platform sed implementation
cross_platform_sed() {
    local file=$1
    local pattern=$2
    local replacement=$3

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "$pattern$replacement" "$file"
    else
        # Linux/others
        sed -i "$pattern$replacement" "$file"
    fi
}

# ===== MAIN SCRIPT =====

# Check dependencies
check_dependency "node" "Visit https://nodejs.org/"
check_dependency "npm" "Included with Node.js"

# Check Node.js version
NODE_VERSION=$(node -v | cut -d 'v' -f 2)
NODE_MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d '.' -f 1)

if [ "$NODE_MAJOR_VERSION" -lt 14 ]; then
    show_warning "You're using Node.js v$NODE_VERSION"
    show_warning "React projects generally require Node.js v14.0.0 or higher."
    echo -e "Do you want to continue anyway? (y/n)"
    read -r continue_anyway

    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        error_exit "Exiting. Please upgrade Node.js and try again."
    fi
fi

# Find TSX files
echo -e "${BOLD}Searching for TSX files...${RESET}"

# Find all TSX files in the current directory
TSX_FILES=()
for file in *.tsx; do
    if [[ -f "$file" ]]; then
        TSX_FILES+=("$file")
    fi
done

TSX_COUNT=${#TSX_FILES[@]}

# Handle TSX file selection
if [[ $TSX_COUNT -eq 0 ]]; then
    show_warning "No TSX files found in the current directory."

    # Option to search recursively
    echo -e "Would you like to search recursively in subdirectories? (y/n)"
    read -r search_recursively

    if [[ "$search_recursively" =~ ^[Yy]$ ]]; then
        echo -e "${BOLD}Searching recursively for TSX files...${RESET}"
        mapfile -t TSX_FILES < <(find . -type f -name "*.tsx" | sed 's|^\./||' | sort)
        TSX_COUNT=${#TSX_FILES[@]}

        if [[ $TSX_COUNT -eq 0 ]]; then
            show_warning "Still no TSX files found."
            echo -e "Please provide the relative path to your TSX file:"
            read -r TSX_FILE

            if [[ ! -f "$TSX_FILE" ]]; then
                error_exit "File not found: $TSX_FILE\nPlease check the path and try again."
            fi
        elif [[ $TSX_COUNT -eq 1 ]]; then
            TSX_FILE="${TSX_FILES[0]}"
            show_success "Using: $TSX_FILE"
        else
            TSX_FILE=$(select_tsx_file "${TSX_FILES[@]}")
        fi
    else
        echo -e "Please provide the relative path to your TSX file:"
        read -r TSX_FILE

        if [[ ! -f "$TSX_FILE" ]]; then
            error_exit "File not found: $TSX_FILE\nPlease check the path and try again."
        fi
    fi
elif [[ $TSX_COUNT -eq 1 ]]; then
    TSX_FILE="${TSX_FILES[0]}"
    show_success "Using TSX file: $TSX_FILE"
else
    TSX_FILE=$(select_tsx_file "${TSX_FILES[@]}")
fi

# Verify the TSX file exists
if [[ ! -f "$TSX_FILE" ]]; then
    error_exit "TSX file '$TSX_FILE' not found. Please check the path and try again."
fi

# Analyze TSX file
echo -e "${BOLD}Analyzing $TSX_FILE...${RESET}"

# Check if it's likely a React component
if ! grep -q -E "import React|from ['\"]react['\"]|useState|useEffect|useContext|React\.Component|extends Component|<[A-Z][A-Za-z0-9]*|function [A-Z][A-Za-z0-9_]*\(|const [A-Z][A-Za-z0-9_]* = \(|return \(" "$TSX_FILE"; then
    show_warning "This file may not be a React component."
    echo -e "Continue anyway? (y/n)"
    read -r continue_anyway

    if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
        error_exit "Exiting. Please select a valid React component file."
    fi
fi

# Determine the component name
COMPONENT_NAME=""
if grep -q "export default" "$TSX_FILE"; then
    COMPONENT_NAME=$(grep -E "export default (\w+)" "$TSX_FILE" | sed -E 's/.*export default ([A-Za-z0-9_]+).*/\1/')
elif grep -q "export const" "$TSX_FILE"; then
    COMPONENT_NAME=$(grep -E "export const (\w+)" "$TSX_FILE" | sed -E 's/.*export const ([A-Za-z0-9_]+).*/\1/')
fi

# If component name wasn't found, use filename
if [[ -z "$COMPONENT_NAME" ]]; then
    COMPONENT_NAME=$(basename "$TSX_FILE" .tsx)
    # Make first character uppercase for component name convention
    COMPONENT_NAME="$(tr '[:lower:]' '[:upper:]' <<< ${COMPONENT_NAME:0:1})${COMPONENT_NAME:1}"
    show_warning "Couldn't determine component name from file content."
    show_warning "Using '$COMPONENT_NAME' based on the file name."
fi

# Project name
PROJECT_NAME="dashboard"

# Check for existing project
if [ -d "$PROJECT_NAME" ]; then
    show_warning "A project named '$PROJECT_NAME' already exists."
    echo -e "What would you like to do?"
    echo -e "[1] Use a different name"
    echo -e "[2] Delete the existing project and create a new one"
    echo -e "[3] Abort"
    read -r existing_project_choice

    case $existing_project_choice in
        1)
            echo -e "Enter a new project name:"
            read -r PROJECT_NAME
            ;;
        2)
            show_warning "Removing existing project directory..."
            rm -rf "$PROJECT_NAME"
            ;;
        *)
            error_exit "Aborting."
            ;;
    esac
fi

# Check for Tailwind
echo -e "${BOLD}Checking for UI libraries in $TSX_FILE...${RESET}"
NEEDS_TAILWIND=false

if grep -q "className=.*" "$TSX_FILE" && grep -q "bg-\|text-\|flex\|grid\|p-\|m-\|rounded" "$TSX_FILE"; then
    show_info "Detected Tailwind CSS classes in the component."
    NEEDS_TAILWIND=true
fi

# Setup method selection
echo -e "${BOLD}Please select a setup method:${RESET}"
echo -e "[1] ${BLUE}Vite${RESET} (Fast Development)"
echo -e "[2] ${YELLOW}Next.js${RESET} (Production Ready)"
echo ""
echo -e "Enter your choice (1-2):"
read -r METHOD_CHOICE

# Detect export type for import statement
if grep -q "export default" "$TSX_FILE"; then
    IMPORT_TYPE="default"
else
    IMPORT_TYPE="named"
fi

# Setup based on the selected method
case $METHOD_CHOICE in
    1) # Vite setup
        echo -e "${BOLD}🛠️ Setting up with Vite...${RESET}"
        echo -e "Creating a new project: $PROJECT_NAME"
        npm create vite@latest "$PROJECT_NAME" -- --template react-ts

        cd "$PROJECT_NAME" || error_exit "Failed to navigate to project directory."

        echo -e "${BLUE}Installing dependencies...${RESET}"
        npm install

        mkdir -p src/components
        cp "../$TSX_FILE" "src/components/${COMPONENT_NAME}.tsx"

        # Install Tailwind if needed
        if [ "$NEEDS_TAILWIND" = true ]; then
            echo -e "${BLUE}Installing Tailwind CSS...${RESET}"
            npm install -D tailwindcss postcss autoprefixer
            npx tailwindcss init -p

            cat > tailwind.config.js << EOF
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

            cat > src/index.css << EOF
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
        fi

        # Create App.tsx with the component
        IMPORT_STATEMENT=""
        if [ "$IMPORT_TYPE" = "default" ]; then
            IMPORT_STATEMENT="import $COMPONENT_NAME from './components/$COMPONENT_NAME';"
        else
            IMPORT_STATEMENT="import { $COMPONENT_NAME } from './components/$COMPONENT_NAME';"
        fi

        cat > src/App.tsx << EOF
import './App.css'
$IMPORT_STATEMENT

function App() {
  return (
    <div className="App">
      <$COMPONENT_NAME />
    </div>
  )
}

export default App
EOF

        show_success "Setup complete! Starting the development server..."
        echo -e "Your app will be available at ${BOLD}http://localhost:5173${RESET}"
        npm run dev
        ;;

    2) # Next.js setup
        echo -e "${BOLD}🛠️ Setting up with Next.js...${RESET}"
        echo -e "Creating a new project: $PROJECT_NAME"
        CI=1 npx create-next-app@latest "$PROJECT_NAME" --typescript --tailwind --app --src-dir --use-npm --no-interactive

        cd "$PROJECT_NAME" || error_exit "Failed to navigate to project directory."

        mkdir -p src/components
        cp "../$TSX_FILE" "src/components/${COMPONENT_NAME}.tsx"

        # Add "use client" directive at the top of the component file
        echo -e "${BLUE}Adding 'use client' directive to component...${RESET}"
        echo '"use client";' | cat - "src/components/${COMPONENT_NAME}.tsx" > temp && mv temp "src/components/${COMPONENT_NAME}.tsx"

        # Create a page that uses the component
        mkdir -p src/app

        if [ "$IMPORT_TYPE" = "default" ]; then
            IMPORT_LINE="import $COMPONENT_NAME from \"../components/$COMPONENT_NAME\";"
        else
            IMPORT_LINE="import { $COMPONENT_NAME } from \"../components/$COMPONENT_NAME\";"
        fi

        cat > "src/app/page.tsx" << EOF
'use client'
$IMPORT_LINE

export default function Home() {
  return (
    <${COMPONENT_NAME} />
  );
}
EOF

        show_success "Setup complete! Starting the development server..."
        echo -e "Your app will be available at ${BOLD}http://localhost:3000${RESET}"
        npm run dev
        ;;

    *)
        error_exit "Invalid choice. Please run the script again and select a valid option (1-2)."
        ;;
esac

# End of script message
echo -e "${BOLD}${GREEN}React app successfully created and started!${RESET}"
