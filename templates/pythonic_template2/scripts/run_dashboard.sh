#!/bin/bash

# Define colors for better user experience
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${BLUE}=== Project Template - Dashboard Runner ===${NC}"
echo "This script helps you run the project dashboard."
echo ""

# Check if .env file exists
if [ ! -f "$ROOT_DIR/.env" ]; then
    echo -e "${YELLOW}Warning: .env file not found. Some features may not work properly.${NC}"
    echo -e "Consider running './scripts/setup_env.sh' first to set up your environment."
    echo ""
fi

# Prompt user to choose between Docker and directly running the app
echo "Please choose how you would like to run the dashboard:"
echo -e "${BLUE}1)${NC} Docker (recommended for production use)"
echo -e "${BLUE}2)${NC} Local env (recommended for development)"
echo ""

read -p "Enter your choice (1/2): " choice

case $choice in
    1)
        echo -e "${GREEN}Starting Docker container...${NC}"
        "$SCRIPT_DIR/run_docker.sh" start
        ;;
    2)
        echo -e "${GREEN}Starting application directly...${NC}"

        # Check if virtual environment exists and activate if found
        if [ -d "$ROOT_DIR/.venv" ]; then
            echo -e "${BLUE}Using virtual environment...${NC}"
            source "$ROOT_DIR/.venv/bin/activate" || source "$ROOT_DIR/.venv/Scripts/activate"
        else
            # Check if we're in a conda environment
            if command -v conda &> /dev/null && [ -n "$CONDA_DEFAULT_ENV" ]; then
                echo -e "${BLUE}Using conda environment: $CONDA_DEFAULT_ENV${NC}"
            else
                echo -e "${YELLOW}Warning: No virtual environment detected, using system Python.${NC}"
                echo -e "Consider running './scripts/install.sh' first to set up your environment."
            fi
        fi

        # Determine the application entry point
        APP_PATH=""
        if [ -f "$ROOT_DIR/te_koa/visualization/app.py" ]; then
            APP_PATH="te_koa/visualization/app.py"
        elif [ -f "$ROOT_DIR/te_koa/dashboard/app.py" ]; then
            APP_PATH="te_koa/dashboard/app.py"
        elif [ -f "$ROOT_DIR/te_koa/app.py" ]; then
            APP_PATH="te_koa/app.py"
        elif [ -f "$ROOT_DIR/te_koa/main.py" ]; then
            APP_PATH="te_koa/main.py"
        else
            echo -e "${YELLOW}No application entry point found. Please specify the path:${NC}"
            read -p "Enter the relative path to your application file: " custom_path
            APP_PATH="$custom_path"
        fi

        # Check if streamlit is installed
        if command -v streamlit &> /dev/null; then
            # Run with Streamlit if it's installed
            cd "$ROOT_DIR"
            echo -e "${GREEN}Starting Streamlit application: $APP_PATH${NC}"
            streamlit run "$APP_PATH" --server.runOnSave=true
        else
            # Otherwise run as a Python script
            cd "$ROOT_DIR"
            echo -e "${GREEN}Starting Python application: $APP_PATH${NC}"
            python "$APP_PATH"
        fi
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac
